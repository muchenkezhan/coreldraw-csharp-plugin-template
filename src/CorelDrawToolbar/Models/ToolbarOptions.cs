namespace CorelDrawToolbar.Models
{
    public sealed class ToolbarOptions
    {
        public const string ProductName = "PCodex CorelDRAW Toolkit";

        public string ArtisticText { get; set; } = "PCodex 创意工具";
        public double PageMarginPercent { get; set; } = 10.0;
        public double OffsetX { get; set; } = 10.0;
        public double OffsetY { get; set; } = -10.0;
        public string FillPresetId { get; set; } = "pcodex-green";
        public byte FillRed { get; set; } = 42;
        public byte FillGreen { get; set; } = 168;
        public byte FillBlue { get; set; } = 116;
        public bool ShowCompletionDialog { get; set; } = false;

        public string FillSummary => $"RGB({FillRed}, {FillGreen}, {FillBlue})";

        public void ApplyFillPreset(string presetId)
        {
            FillPresetId = presetId;
            switch (presetId)
            {
                case "corel-cyan":
                    SetFill(39, 163, 209);
                    break;
                case "creative-purple":
                    SetFill(132, 91, 190);
                    break;
                case "alert-orange":
                    SetFill(232, 142, 55);
                    break;
                default:
                    FillPresetId = "pcodex-green";
                    SetFill(42, 168, 116);
                    break;
            }
        }

        public ToolbarOptions Clone()
        {
            return new ToolbarOptions
            {
                ArtisticText = ArtisticText,
                PageMarginPercent = PageMarginPercent,
                OffsetX = OffsetX,
                OffsetY = OffsetY,
                FillPresetId = FillPresetId,
                FillRed = FillRed,
                FillGreen = FillGreen,
                FillBlue = FillBlue,
                ShowCompletionDialog = ShowCompletionDialog
            };
        }

        public void CopyFrom(ToolbarOptions source)
        {
            ArtisticText = source.ArtisticText;
            PageMarginPercent = source.PageMarginPercent;
            OffsetX = source.OffsetX;
            OffsetY = source.OffsetY;
            FillPresetId = source.FillPresetId;
            FillRed = source.FillRed;
            FillGreen = source.FillGreen;
            FillBlue = source.FillBlue;
            ShowCompletionDialog = source.ShowCompletionDialog;
        }

        private void SetFill(byte red, byte green, byte blue)
        {
            FillRed = red;
            FillGreen = green;
            FillBlue = blue;
        }
    }
}
