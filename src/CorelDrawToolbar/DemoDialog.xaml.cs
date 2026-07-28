using System.Globalization;
using System.Windows;
using CorelDrawToolbar.Models;

namespace CorelDrawToolbar
{
    public partial class DemoDialog : Window
    {
        private readonly ToolbarOptions _workingCopy;

        public ToolbarOptions Result => _workingCopy;

        public DemoDialog(ToolbarOptions current)
        {
            InitializeComponent();
            _workingCopy = current.Clone();
            ArtisticTextInput.Text = _workingCopy.ArtisticText;
            OffsetXInput.Text = FormatNumber(_workingCopy.OffsetX);
            OffsetYInput.Text = FormatNumber(_workingCopy.OffsetY);
            PageMarginInput.Text = FormatNumber(_workingCopy.PageMarginPercent);
            FillPresetInput.SelectedValue = _workingCopy.FillPresetId;
            CompletionDialogInput.IsChecked = _workingCopy.ShowCompletionDialog;
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            string artisticText = ArtisticTextInput.Text.Trim();
            if (artisticText.Length == 0)
            {
                ShowValidation("默认艺术字文案不能为空。");
                return;
            }

            if (!TryReadNumber(OffsetXInput.Text, -10000, 10000, out double offsetX) ||
                !TryReadNumber(OffsetYInput.Text, -10000, 10000, out double offsetY))
            {
                ShowValidation("偏移量必须是 -10000 到 10000 之间的数字。");
                return;
            }

            if (!TryReadNumber(PageMarginInput.Text, 0, 45, out double pageMargin))
            {
                ShowValidation("页面边距必须是 0 到 45 之间的百分比。");
                return;
            }

            _workingCopy.ArtisticText = artisticText;
            _workingCopy.OffsetX = offsetX;
            _workingCopy.OffsetY = offsetY;
            _workingCopy.PageMarginPercent = pageMargin;
            _workingCopy.ApplyFillPreset(FillPresetInput.SelectedValue as string ?? "pcodex-green");
            _workingCopy.ShowCompletionDialog = CompletionDialogInput.IsChecked == true;
            DialogResult = true;
        }

        private static bool TryReadNumber(string value, double minimum, double maximum, out double result)
        {
            bool parsed = double.TryParse(value, NumberStyles.Float, CultureInfo.CurrentCulture, out result) ||
                          double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out result);
            return parsed && result >= minimum && result <= maximum;
        }

        private static string FormatNumber(double value)
        {
            return value.ToString("0.###", CultureInfo.CurrentCulture);
        }

        private static void ShowValidation(string message)
        {
            MessageBox.Show(message, "PCodex 参数检查", MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }
}
