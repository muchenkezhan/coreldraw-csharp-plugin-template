using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Windows.Controls;
using System.Windows.Threading;

namespace CorelDrawToolbar
{
    // CorelDRAW hosts this one-pixel control so native commands remain independent toolbar items.
    [ComVisible(true)]
    [Guid("89d68c84-2b22-536f-806d-69b0e9e39c8a")]
    public sealed class NativeCommandHost : UserControl
    {
        // Strong reference keeps the nonvisual command dispatcher alive for native items.
        private ControlUI _commandDispatcher;
        private DispatcherTimer _floatingToolbarSizeTimer;
        private bool _floatingToolbarSizeSyncStarted;

        public NativeCommandHost(object application)
        {
            NativeToolbarLog.Write("NativeCommandHost constructed; application=" + (application == null ? "null" : application.GetType().FullName));
            Width = 1;
            Height = 1;
            MinWidth = 1;
            MinHeight = 1;
            Opacity = 0.0;
            IsHitTestVisible = false;
            Focusable = false;
            ScheduleInitialization(application);
        }

        private void ScheduleInitialization(object application)
        {
            Loaded += (sender, args) =>
            {
                EnsureInitialized(application);
                StartFloatingToolbarAutoHeightSync();
            };
            EnsureInitialized(application);
            Dispatcher.BeginInvoke(
                new Action(() =>
                {
                    EnsureInitialized(application);
                    StartFloatingToolbarAutoHeightSync();
                }),
                DispatcherPriority.ContextIdle);
        }

        private void EnsureInitialized(object application)
        {
            NativeToolbarLog.Write("EnsureInitialized invoked.");
            if (_commandDispatcher != null)
            {
                NativeCommandBridge.EnsureRegistered();
                return;
            }

            object resolvedApplication = NativeCommandBridge.ResolveApplication(application);
            if (resolvedApplication == null)
            {
                NativeToolbarLog.Write("CorelDRAW application could not be resolved.");
                return;
            }
            _commandDispatcher = new ControlUI(resolvedApplication);
            NativeCommandBridge.Initialize(resolvedApplication);
        }

        private void StartFloatingToolbarAutoHeightSync()
        {
            if (_floatingToolbarSizeSyncStarted) return;
            _floatingToolbarSizeSyncStarted = true;
            _floatingToolbarSizeTimer = new DispatcherTimer(DispatcherPriority.Background)
            {
                Interval = TimeSpan.FromMilliseconds(180)
            };
            _floatingToolbarSizeTimer.Tick += (sender, args) => SyncFloatingToolbarHeights();
            _floatingToolbarSizeTimer.Start();
            SyncFloatingToolbarHeights();
        }

        private static void SyncFloatingToolbarHeights()
        {
            uint currentProcessId = (uint)Process.GetCurrentProcess().Id;
            EnumWindows((windowHandle, parameter) =>
            {
                uint processId;
                GetWindowThreadProcessId(windowHandle, out processId);
                if (processId != currentProcessId || !IsWindowVisible(windowHandle)) return true;
                if (!string.Equals(GetWindowTitle(windowHandle), "PCodex Demo 工具栏", StringComparison.Ordinal)) return true;
                WindowRect windowRect;
                if (!GetWindowRect(windowHandle, out windowRect)) return true;
                int width = windowRect.Right - windowRect.Left;
                int currentHeight = windowRect.Bottom - windowRect.Top;
                int expectedHeight = GetExpectedFloatingToolbarHeight(width);
                if (Math.Abs(currentHeight - expectedHeight) > 2)
                {
                    SetWindowPos(windowHandle, IntPtr.Zero, 0, 0, width, expectedHeight,
                        NoMove | NoZOrder | NoActivate);
                }
                return true;
            }, IntPtr.Zero);
        }

        private static int GetExpectedFloatingToolbarHeight(int windowWidth)
        {
            int[] itemWidths = { 126, 116, 128, 124, 98 };
            int usableWidth = Math.Max(96, windowWidth - 18);
            int rows = 1;
            int usedWidth = 0;
            foreach (int itemWidth in itemWidths)
            {
                if (usedWidth > 0 && usedWidth + itemWidth > usableWidth)
                {
                    rows++;
                    usedWidth = 0;
                }
                usedWidth += itemWidth;
            }
            return Math.Max(57, 27 + (rows * 30));
        }

        private static string GetWindowTitle(IntPtr windowHandle)
        {
            var title = new StringBuilder(256);
            GetWindowText(windowHandle, title, title.Capacity);
            return title.ToString();
        }

        private const uint NoMove = 0x0002;
        private const uint NoZOrder = 0x0004;
        private const uint NoActivate = 0x0010;

        private delegate bool EnumWindowsCallback(IntPtr windowHandle, IntPtr parameter);

        [StructLayout(LayoutKind.Sequential)]
        private struct WindowRect
        {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumWindowsCallback callback, IntPtr parameter);

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr windowHandle, out uint processId);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowText(IntPtr windowHandle, StringBuilder title, int maxCount);

        [DllImport("user32.dll")]
        private static extern bool GetWindowRect(IntPtr windowHandle, out WindowRect windowRect);

        [DllImport("user32.dll")]
        private static extern bool IsWindowVisible(IntPtr windowHandle);

        [DllImport("user32.dll")]
        private static extern bool SetWindowPos(
            IntPtr windowHandle, IntPtr insertAfter, int x, int y, int width, int height, uint flags);
    }

    internal static class NativeCommandBridge
    {
        private static readonly object SyncRoot = new object();
        private static readonly Dictionary<string, CommandDefinition> Commands =
            new Dictionary<string, CommandDefinition>(StringComparer.OrdinalIgnoreCase)
            {
                { "PCodex_CreatePageRectangle", new CommandDefinition("PCodex_CreatePageRectangle", "页面比例矩形", "按当前参数创建页面比例矩形") },
                { "PCodex_CreateArtisticText", new CommandDefinition("PCodex_CreateArtisticText", "PCodex 艺术字", "创建当前默认文案的艺术字") },
                { "PCodex_CreateSample", new CommandDefinition("PCodex_CreateSample", "PCodex 组合样例", "创建带默认填充和文案的组合样例") },
                { "PCodex_DuplicateOffset", new CommandDefinition("PCodex_DuplicateOffset", "复制并偏移", "复制当前选区并按默认参数偏移") },
                { "PCodex_CenterSelection", new CommandDefinition("PCodex_CenterSelection", "居中到页面", "将当前选区居中到活动页面") },
                { "PCodex_ApplyDemoFill", new CommandDefinition("PCodex_ApplyDemoFill", "应用当前填充", "将当前填充预设应用到选区") },
                { "PCodex_ShowSelectionInfo", new CommandDefinition("PCodex_ShowSelectionInfo", "显示选区信息", "查看当前选区的尺寸和数量") },
                { "PCodex_OpenSettings", new CommandDefinition("PCodex_OpenSettings", "编辑默认参数", "打开 PCodex 默认参数窗口") },
                { "PCodex_ShowAbout", new CommandDefinition("PCodex_ShowAbout", "关于 PCodex Demo", "查看模板说明") },
            };

        private static dynamic _application;
        private static IConnectionPoint _connectionPoint;
        private static int _connectionCookie;
        private static CorelApplicationEventSink _eventSink;
        private static ControlUI _dispatcher;
        private static bool _subscribed;
        private static bool _commandsRegistered;

        public static void Attach(ControlUI dispatcher, object application)
        {
            if (dispatcher == null) throw new ArgumentNullException(nameof(dispatcher));
            lock (SyncRoot)
            {
                _dispatcher = dispatcher;
            }
            Initialize(application);
        }

        public static void Initialize(object application)
        {
            NativeToolbarLog.Write("NativeCommandBridge.Initialize invoked.");
            application = ResolveApplication(application);
            if (application == null) return;
            try
            {
                lock (SyncRoot)
                {
                    if (_application == null)
                    {
                        _application = application;
                    }
                    if (_application == null) return;
                    RegisterCommands();
                    SubscribePluginCommandEvents();
                }
            }
            catch (Exception exception)
            {
                Debug.WriteLine("PCodex native command bridge initialization failed: " + exception);
                NativeToolbarLog.Write("Bridge initialization failed: " + exception);
            }
        }

        internal static object ResolveApplication(object application)
        {
            if (application != null) return application;
            string programId = ResolveCurrentHostProgramId();
            if (string.IsNullOrWhiteSpace(programId)) return null;
            try
            {
                object activeApplication = Marshal.GetActiveObject(programId);
                if (activeApplication != null) return activeApplication;
            }
            catch (COMException)
            {
                // CorelDRAW can register its ROT entry after Addons start loading.
            }
            try
            {
                Type applicationType = Type.GetTypeFromProgID(programId, false);
                return applicationType == null ? null : Activator.CreateInstance(applicationType);
            }
            catch (COMException)
            {
                return null;
            }
        }

        private static string ResolveCurrentHostProgramId()
        {
            try
            {
                string executablePath = Process.GetCurrentProcess().MainModule.FileName;
                int majorVersion = FileVersionInfo.GetVersionInfo(executablePath).FileMajorPart;
                return majorVersion > 0 ? "CorelDRAW.Application." + majorVersion : null;
            }
            catch (Exception exception)
            {
                Debug.WriteLine("PCodex could not resolve the current CorelDRAW version: " + exception);
                return null;
            }
        }

        public static void EnsureRegistered()
        {
            lock (SyncRoot)
            {
                if (_application == null) return;
                RegisterCommands();
            }
        }

        private static void RegisterCommands()
        {
            if (_commandsRegistered) return;
            foreach (CommandDefinition command in Commands.Values)
            {
                _application.AddPluginCommand(command.Id, command.Caption, command.ToolTip);
            }
            _commandsRegistered = true;
        }

        private static void SubscribePluginCommandEvents()
        {
            if (_subscribed) return;
            var container = (object)_application as IConnectionPointContainer;
            if (container == null) throw new InvalidOperationException("当前 CorelDRAW 宿主不支持插件命令事件。");
            Guid eventInterfaceGuid = typeof(ICorelApplicationEventSink).GUID;
            container.FindConnectionPoint(ref eventInterfaceGuid, out _connectionPoint);
            _eventSink = new CorelApplicationEventSink();
            _connectionPoint.Advise(_eventSink, out _connectionCookie);
            _subscribed = true;
        }

        internal static void HandlePluginCommand(string commandId)
        {
            if (!Commands.ContainsKey(commandId) || !TryGetDispatcher(out ControlUI dispatcher)) return;
            Action dispatch = () => dispatcher.ExecuteNativeCommand(commandId);
            if (dispatcher.Dispatcher.CheckAccess())
            {
                dispatch();
            }
            else
            {
                dispatcher.Dispatcher.BeginInvoke(dispatch, DispatcherPriority.Normal);
            }
        }

        internal static void HandleUpdatePluginCommand(
            string commandId,
            ref bool enabled,
            ref int checkedState)
        {
            if (!Commands.ContainsKey(commandId)) return;
            enabled = TryGetDispatcher(out ControlUI dispatcher);
            checkedState = 0;
        }

        private static bool TryGetDispatcher(out ControlUI dispatcher)
        {
            lock (SyncRoot)
            {
                if (_dispatcher != null)
                {
                    dispatcher = _dispatcher;
                    return true;
                }
            }
            dispatcher = null;
            return false;
        }

        private sealed class CommandDefinition
        {
            public CommandDefinition(string id, string caption, string toolTip)
            {
                Id = id;
                Caption = caption;
                ToolTip = toolTip;
            }

            public string Id { get; }
            public string Caption { get; }
            public string ToolTip { get; }
        }
    }

    internal static class NativeToolbarLog
    {
        private static readonly object SyncRoot = new object();

        public static void Write(string message)
        {
            try
            {
                lock (SyncRoot)
                {
                    string directory = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                        "PCodex",
                        "CorelDrawToolbar");
                    Directory.CreateDirectory(directory);
                    string entry = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") +
                        " " + message + Environment.NewLine;
                    File.AppendAllText(Path.Combine(directory, "native-toolbar.log"), entry);
                }
            }
            catch
            {
                // Diagnostics must never affect the CorelDRAW host.
            }
        }
    }

    [ComVisible(true)]
    [Guid("B05800C5-9AA4-44FD-9547-4F91EB757AC4")]
    [InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
    public interface ICorelApplicationEventSink
    {
        [DispId(20)]
        void OnPluginCommand([MarshalAs(UnmanagedType.BStr)] string commandId);

        [DispId(21)]
        void OnUpdatePluginCommand(
            [MarshalAs(UnmanagedType.BStr)] string commandId,
            [In, Out] ref bool enabled,
            [In, Out] ref int checkedState);
    }

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    public sealed class CorelApplicationEventSink : ICorelApplicationEventSink
    {
        public void OnPluginCommand(string commandId)
        {
            NativeToolbarLog.Write("OnPluginCommand received: " + commandId);
            NativeCommandBridge.HandlePluginCommand(commandId);
        }

        public void OnUpdatePluginCommand(string commandId, ref bool enabled, ref int checkedState)
        {
            NativeCommandBridge.HandleUpdatePluginCommand(commandId, ref enabled, ref checkedState);
        }
    }
}
