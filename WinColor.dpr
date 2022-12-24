program WinColor;

{$R *.res}


uses
  Forms,
  uWinColor in 'uWinColor.pas' {fmMain},
  uRegistry in 'uRegistry.pas',
  uPngImageShadowButton in 'uPngImageShadowButton.pas',
  uPngImageButton in 'uPngImageButton.pas',
  cryptokey in 'cryptokey.pas';

begin
      Application.Initialize;
  Application.Title := 'Color psychology for windows';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.
