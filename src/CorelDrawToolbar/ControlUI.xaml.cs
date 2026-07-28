using System;
using System.Windows;
using System.Windows.Controls;
using CorelDrawToolbar.Models;
using CorelDrawToolbar.Services;

namespace CorelDrawToolbar
{
    public partial class ControlUI : UserControl
    {
        private readonly CorelDrawToolbarService _corelDraw;
        private readonly ToolbarOptions _options;
        private readonly object _application;

        public ControlUI(object application)
        {
            _application = application ?? throw new ArgumentNullException(nameof(application));
            _options = new ToolbarOptions();
            InitializeComponent();
            _corelDraw = new CorelDrawToolbarService(_application, _options);
            NativeCommandBridge.Attach(this, _application);
            Loaded += ControlUI_Loaded;
            FillPresetCombo.SelectedValue = _options.FillPresetId;
            UpdateOptionSummary();
            StatusText.Text = ToolbarOptions.ProductName + " 已连接";
        }

        private void ControlUI_Loaded(object sender, RoutedEventArgs e)
        {
            NativeCommandBridge.Attach(this, _application);
        }

        private void NativeCommand_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.Tag is string commandId)
            {
                ExecuteNativeCommand(commandId);
            }
        }

        internal void ExecuteNativeCommand(string commandId)
        {
            NativeToolbarLog.Write("Executing native command: " + commandId);
            CloseTransientMenus();
            try
            {
                switch (commandId)
                {
                    case "PCodex_CreatePageRectangle":
                        RunAction(_corelDraw.CreatePageRectangle);
                        break;
                    case "PCodex_CreateArtisticText":
                        RunAction(_corelDraw.CreateArtisticText);
                        break;
                    case "PCodex_CreateSample":
                        RunAction(_corelDraw.CreatePCodexSample);
                        break;
                    case "PCodex_DuplicateOffset":
                        RunAction(_corelDraw.DuplicateSelectionWithOffset);
                        break;
                    case "PCodex_CenterSelection":
                        RunAction(_corelDraw.CenterSelectionOnPage);
                        break;
                    case "PCodex_ApplyDemoFill":
                        RunAction(_corelDraw.ApplyDemoFill);
                        break;
                    case "PCodex_ShowSelectionInfo":
                        ShowSelectionInfo();
                        break;
                    case "PCodex_OpenSettings":
                        OpenSettings();
                        break;
                    case "PCodex_ShowAbout":
                        ShowAbout();
                        break;
                    default:
                        throw new InvalidOperationException("未知 PCodex 工具命令：" + commandId);
                }
            }
            catch (Exception exception)
            {
                StatusText.Text = exception.Message;
                MessageBox.Show(exception.Message, "PCodex CorelDRAW 工具栏", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }

        private void FillPresetCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (_options == null || QuickSummaryText == null || !(FillPresetCombo.SelectedValue is string presetId)) return;
            _options.ApplyFillPreset(presetId);
            UpdateOptionSummary();
        }

        private void QuickPanelButton_Click(object sender, RoutedEventArgs e)
        {
            QuickPanelPopup.IsOpen = QuickPanelButton.IsChecked == true;
        }

        private void QuickPanelPopup_Closed(object sender, EventArgs e)
        {
            QuickPanelButton.IsChecked = false;
        }

        private void OpenSettings()
        {
            var dialog = new DemoDialog(_options);
            var owner = Window.GetWindow(this);
            if (owner != null) dialog.Owner = owner;
            if (dialog.ShowDialog() == true)
            {
                _options.CopyFrom(dialog.Result);
                FillPresetCombo.SelectedValue = _options.FillPresetId;
                UpdateOptionSummary();
                StatusText.Text = "PCodex 参数已更新";
            }
        }

        private void ShowSelectionInfo()
        {
            RunAction(() =>
            {
                var information = _corelDraw.GetSelectionInfo();
                MessageBox.Show(information, "CorelDRAW 选区信息", MessageBoxButton.OK, MessageBoxImage.Information);
                return "已读取选区信息";
            });
        }

        private void ShowAbout()
        {
            MessageBox.Show(
                "PCodex CorelDRAW Toolkit\n\nWPF Addon 交互模板 Demo\n包含菜单、下拉框、Popup 和参数弹窗。",
                "关于 PCodex Demo",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
        }

        private void UpdateOptionSummary()
        {
            QuickSummaryText.Text = "文案：" + _options.ArtisticText + Environment.NewLine +
                "填充：" + _options.FillSummary + " · 偏移：" + _options.OffsetX.ToString("0.##") + ", " + _options.OffsetY.ToString("0.##");
        }

        private void CloseTransientMenus()
        {
            foreach (object item in ToolbarMenu.Items)
            {
                if (item is MenuItem menuItem) menuItem.IsSubmenuOpen = false;
            }
            QuickPanelPopup.IsOpen = false;
            QuickPanelButton.IsChecked = false;
        }

        private void RunAction(Func<string> action)
        {
            try
            {
                StatusText.Text = action();
                if (_options.ShowCompletionDialog)
                {
                    MessageBox.Show(StatusText.Text, "PCodex 操作完成", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
            catch (Exception exception)
            {
                StatusText.Text = exception.Message;
                MessageBox.Show(exception.Message, "CorelDRAW 工具栏", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }
    }
}
