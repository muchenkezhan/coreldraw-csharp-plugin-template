using System;
using System.Globalization;
using CorelDrawToolbar.Models;

namespace CorelDrawToolbar.Services
{
    public sealed class CorelDrawToolbarService
    {
        private readonly dynamic _application;
        private readonly ToolbarOptions _options;

        public CorelDrawToolbarService(object application, ToolbarOptions options)
        {
            _application = application ?? throw new ArgumentNullException(nameof(application));
            _options = options ?? throw new ArgumentNullException(nameof(options));
        }

        public string CreatePageRectangle()
        {
            dynamic document = GetOrCreateDocument();
            return RunCommand((object)document, "创建页面矩形", () =>
            {
                dynamic page = document.ActivePage;
                double width = ToDouble(page.SizeWidth);
                double height = ToDouble(page.SizeHeight);
                double left = ReadPageLeft(page);
                double bottom = ReadPageBottom(page);
                double margin = _options.PageMarginPercent / 100.0;
                document.ActiveLayer.CreateRectangle2(
                    left + width * margin,
                    bottom + height * margin,
                    width * (1.0 - margin * 2.0),
                    height * (1.0 - margin * 2.0));
                return $"已创建 PCodex 页面矩形（边距 {_options.PageMarginPercent:0.##}%）";
            });
        }

        public string CreateArtisticText()
        {
            dynamic document = GetOrCreateDocument();
            return RunCommand((object)document, "创建艺术字", () =>
            {
                dynamic page = document.ActivePage;
                double width = ToDouble(page.SizeWidth);
                double height = ToDouble(page.SizeHeight);
                double left = ReadPageLeft(page);
                double bottom = ReadPageBottom(page);
                document.ActiveLayer.CreateArtisticText(
                    left + width * 0.25,
                    bottom + height * 0.5,
                    _options.ArtisticText);
                return "已创建艺术字：" + _options.ArtisticText;
            });
        }

        public string CreatePCodexSample()
        {
            dynamic document = GetOrCreateDocument();
            return RunCommand((object)document, "创建 PCodex 组合样例", () =>
            {
                dynamic page = document.ActivePage;
                dynamic layer = document.ActiveLayer;
                double width = ToDouble(page.SizeWidth);
                double height = ToDouble(page.SizeHeight);
                double left = ReadPageLeft(page);
                double bottom = ReadPageBottom(page);
                double sampleWidth = width * 0.58;
                double sampleHeight = height * 0.24;
                double sampleLeft = left + (width - sampleWidth) / 2.0;
                double sampleBottom = bottom + (height - sampleHeight) / 2.0;
                dynamic color = CreateSelectedColor();
                dynamic background = layer.CreateRectangle2(sampleLeft, sampleBottom, sampleWidth, sampleHeight);
                background.Fill.ApplyUniformFill(color);
                dynamic title = layer.CreateArtisticText(
                    sampleLeft + sampleWidth * 0.12,
                    sampleBottom + sampleHeight * 0.52,
                    _options.ArtisticText);
                title.Fill.ApplyUniformFill(_application.CreateRGBColor(255, 255, 255));
                return "已创建 PCodex 组合样例 · " + _options.FillSummary;
            });
        }

        public string DuplicateSelectionWithOffset()
        {
            dynamic document = RequireDocument();
            dynamic selection = RequireSelection(document);
            return RunCommand((object)document, "复制并偏移选区", () =>
            {
                selection.Duplicate(_options.OffsetX, _options.OffsetY);
                return $"已复制选区并偏移 ({_options.OffsetX:0.##}, {_options.OffsetY:0.##})";
            });
        }

        public string CenterSelectionOnPage()
        {
            dynamic document = RequireDocument();
            dynamic selection = RequireSelection(document);
            return RunCommand((object)document, "选区居中到页面", () =>
            {
                dynamic page = document.ActivePage;
                double pageCenterX = ReadPageLeft(page) + ToDouble(page.SizeWidth) / 2.0;
                double pageCenterY = ReadPageBottom(page) + ToDouble(page.SizeHeight) / 2.0;
                selection.Move(
                    pageCenterX - ToDouble(selection.CenterX),
                    pageCenterY - ToDouble(selection.CenterY));
                return "已将选区居中到页面";
            });
        }

        public string ApplyDemoFill()
        {
            dynamic document = RequireDocument();
            dynamic selection = RequireSelection(document);
            return RunCommand((object)document, "应用示例 RGB 填充", () =>
            {
                dynamic color = CreateSelectedColor();
                int count = ToInt32(selection.Count);
                for (int index = 1; index <= count; index++)
                {
                    selection[index].Fill.ApplyUniformFill(color);
                }
                return "已应用 " + _options.FillSummary + " 填充";
            });
        }

        public string GetSelectionInfo()
        {
            dynamic selection = RequireSelection(RequireDocument());
            return string.Join(Environment.NewLine, new[]
            {
                "对象数量: " + ToInt32(selection.Count),
                "宽度: " + FormatNumber(selection.SizeWidth),
                "高度: " + FormatNumber(selection.SizeHeight),
                "中心 X: " + FormatNumber(selection.CenterX),
                "中心 Y: " + FormatNumber(selection.CenterY),
                "PCodex 当前填充: " + _options.FillSummary
            });
        }

        private dynamic CreateSelectedColor()
        {
            return _application.CreateRGBColor(
                Convert.ToInt32(_options.FillRed),
                Convert.ToInt32(_options.FillGreen),
                Convert.ToInt32(_options.FillBlue));
        }

        private dynamic GetOrCreateDocument()
        {
            return ToInt32(_application.Documents.Count) > 0
                ? _application.ActiveDocument
                : _application.CreateDocument();
        }

        private dynamic RequireDocument()
        {
            if (ToInt32(_application.Documents.Count) == 0)
            {
                throw new InvalidOperationException("请先在 CorelDRAW 中打开或创建文档。");
            }
            return _application.ActiveDocument;
        }

        private static dynamic RequireSelection(dynamic document)
        {
            dynamic selection = document.ActiveSelectionRange;
            if (ToInt32(selection.Count) == 0)
            {
                throw new InvalidOperationException("请先选择至少一个对象。");
            }
            return selection;
        }

        private string RunCommand(object documentValue, string commandName, Func<string> action)
        {
            dynamic document = documentValue;
            bool commandGroupStarted = false;
            try
            {
                document.BeginCommandGroup(commandName);
                commandGroupStarted = true;
                string result = action();
                document.EndCommandGroup();
                commandGroupStarted = false;
                TryRefresh();
                return result;
            }
            finally
            {
                if (commandGroupStarted)
                {
                    TryEndCommandGroup(document);
                }
            }
        }

        private void TryRefresh()
        {
            try { _application.Refresh(); } catch { }
        }

        private static void TryEndCommandGroup(dynamic document)
        {
            try { document.EndCommandGroup(); } catch { }
        }

        private static double ReadPageLeft(dynamic page)
        {
            try { return ToDouble(page.LeftX); } catch { return 0.0; }
        }

        private static double ReadPageBottom(dynamic page)
        {
            try { return ToDouble(page.BottomY); } catch { return 0.0; }
        }

        private static int ToInt32(dynamic value)
        {
            return Convert.ToInt32(value, CultureInfo.InvariantCulture);
        }

        private static double ToDouble(dynamic value)
        {
            return Convert.ToDouble(value, CultureInfo.InvariantCulture);
        }

        private static string FormatNumber(dynamic value)
        {
            return ToDouble(value).ToString("0.###", CultureInfo.CurrentCulture);
        }
    }
}
