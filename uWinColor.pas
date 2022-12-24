unit uWinColor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus, MMSystem, StrUtils, pngimage, uRegistry, IOUtils,
  uPngImageButton, uPngImageShadowButton, DECCipherBase, DECCiphers, EncdDecd, cryptokey, Generics.Collections;

const
  cAppName = 'WinColors';
  cAppTitle = 'Win Colors';
  cAppRegistryRoot = '\Software\JGhost\' + cAppName;
  nosound = false;
  HELP_INTRO = 1;
  HELP_NOTES = 2;
  HELP_USE = 3;
  HELP_IMPORTANT = 4;

  Colors: array [0 .. 7] of TColor = ($000000, $0000EE, $00EE00, $EE0000, $00EEEE, $990099, $333366, $999999);

type
  TPageName = (pgHome, pgNameEntry, pgArchive, pgText, pgAbout, pgColors);

  TfmMain = class(TForm)

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);

  private

    Selecting: Integer;
    SelectedColors: array [0 .. 1] of TList<Integer>;

    SndStart: pointer;
    SndClick: pointer;
    SndExit: pointer;
    SndShatter: pointer;

    BtnRun: TPngImageShadowButton;
    BtnDemo: TPngImageShadowButton;
    BtnExit: TPngImageShadowButton;
    BtnArchive: TPngImageShadowButton;

    BtnView: TPngImageShadowButton;
    BtnDelete: TPngImageShadowButton;
    BtnLadyBug: TPngImageShadowButton;

    BtnBack: TPngImageButton;
    BtnPrint: TPngImageButton;

    MemBTabssom: Cardinal;
    ColorList: TListBox;

    PngScrAbout: TPngImage;
    PngScrBg: TPngImage;
    PngScrEnterName: TPngImage;
    PngScrResultBox: TPngImage;
    PngScrScrolls: TPngImage;

    // Colors screen has 3 images, one contains header and choice
    PngScrColorsChoice1: TPngImage;
    PngScrColorsChoice2: TPngImage;
    PngBtnColors: array [0 .. 7] of TPngImage;
    BtnRects: array [0 .. 7] of TRect;
    ColorCodes: TDictionary<string, string>;

    ScreenBuffer: TBitmap;
    Page: TPageName;
    InDemo: Boolean;

    TextHelpIntro: string;
    TextHelpNotes: string;
    TextHelpUse: string;
    TextHelpImportant: string;

    edtName: TEdit;
    lstNames: TListBox;
    LongText: TMemo;
    HelpMenu: TPopupMenu;
    MnuHelpUse: TMenuItem;
    MnuIntro: TMenuItem;
    MnuNote: TMenuItem;
    MnuImportant: TMenuItem;
    MnuLine: TMenuItem;
    MnuAbout: TMenuItem;

    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);

    procedure MnuAboutClick(Sender: TObject);
    procedure TextMenuClick(Sender: TObject);
    procedure edtNameKeyPress(Sender: TObject; var Key: Char);

    procedure BtnRunClick(Sender: TObject);
    procedure BtnDemoClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure BtnArchiveClick(Sender: TObject);

    procedure BtnViewClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure BtnLadyBugClick(Sender: TObject);

    procedure BtnBackClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);

    procedure FormPaint(Sender: TObject);

    procedure ShowPage(APage: TPageName);
    procedure ShowNameEntry;
    procedure ProcessColors;
    procedure BuildForm;
    procedure BuildColorScreen;
    procedure ResetVars;

    procedure SaveHistory;
    procedure LoadHistory;

    procedure PlaySound(SoundPointer: pointer; Options: Integer = SND_NODEFAULT or SND_ASYNC);

    procedure SelectColor(ColorIndex: Integer);
    procedure LoadFont;
    procedure LoadResources;
    function LoadSound(Name: string): pointer;
    function LoadPng(Name: string): TPngImage;
    function LoadText(Name: string): string;
    procedure UnloadResources;
    procedure UnloadFont;
  public
  end;

var
  fmMain: TfmMain;

implementation


{$R *.DFM}
{$R resources.res}
function RemoveFontMemResourceEx(fh: LongWord): LongBool; stdcall; external 'gdi32.dll' Name 'RemoveFontMemResourceEx';

{$REGION 'function decrypt(...): string'}
function decrypt(instr: string; Key: RawByteString; IV: RawByteString = #0#0#0#0#0#0#0#0): string;
var
  Cipher: TCipher_AES128;
  Output: TBytes;
begin
  Cipher := TCipher_AES128.Create;
  Cipher.Init(Key, IV, 0);
  Cipher.Mode := cmCBCx;
  Output := Cipher.DecodeBytes(DecodeBase64(instr));
  result := TEncoding.UTF8.GetString(Output);
  Cipher.Done;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.FormCreate(...)'}
procedure TfmMain.FormCreate(Sender: TObject);
begin
  // Configure Form Properties
  Height := 480;
  Width := 640;
  BorderStyle := bsNone;
  DoubleBuffered := True;
  BiDiMode := bdRightToLeft;
  Position := poDesigned;
  Font.Charset := DEFAULT_CHARSET;
  Font.Name := 'B Tabassom';
  OnMouseDown := FormMouseDown;
  OnKeyPress := FormKeyPress;
  OnPaint := FormPaint;
  OnClick := FormClick;

  LoadFont;
  LoadResources;
  BuildForm;
  LoadFormState(Self, cAppRegistryRoot);
  LoadHistory;

  BuildColorScreen;
  ResetVars;

  // Create Graphic Buffer
  ScreenBuffer := TBitmap.Create;
  ScreenBuffer.Transparent := false;
  ScreenBuffer.Width := Width;
  ScreenBuffer.Height := Height;

  PlaySound(SndStart);
  ShowPage(pgHome);

end;
{$ENDREGION}

{$REGION 'procedure TMainForm.FormClose(...)'}
procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    SaveHistory;
    SaveFormState(Self, cAppRegistryRoot);
  except
  end;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.FormDestroy(...)'}
procedure TfmMain.FormDestroy(Sender: TObject);
begin
  BtnArchive.Free;
  BtnDemo.Free;
  BtnRun.Free;
  BtnExit.Free;

  BtnDelete.Free;
  BtnView.Free;

  BtnLadyBug.Free;
  BtnBack.Free;
  BtnPrint.Free;

  edtName.Free;
  lstNames.Free;
  ColorList.Free;
  LongText.Free;

  MnuHelpUse.Free;
  MnuIntro.Free;
  MnuNote.Free;
  MnuImportant.Free;
  MnuLine.Free;
  MnuAbout.Free;
  HelpMenu.Free;

  ScreenBuffer.Free;

  UnloadResources;

end;
{$ENDREGION}

{$REGION 'procedure TMainForm.FormPaint(...)'}
procedure TfmMain.FormPaint(Sender: TObject);
var
  i: Integer;
  PosX, PosY: Integer;
begin
  inherited;
  ScreenBuffer.Canvas.Draw(0, 0, PngScrBg);
  Case Page of
    pgNameEntry:
      ScreenBuffer.Canvas.Draw(60, 115, PngScrEnterName);
    pgArchive:
      ScreenBuffer.Canvas.Draw(60, 115, PngScrScrolls);
    pgText:
      ScreenBuffer.Canvas.Draw(60, 115, PngScrResultBox);
    pgAbout: begin
        ScreenBuffer.Canvas.Draw(60, 115, PngScrResultBox);
        ScreenBuffer.Canvas.Draw(95, 140, PngScrAbout);
      end;
    pgColors: begin
        if (Selecting = 0) then
            ScreenBuffer.Canvas.Draw(70, 105, PngScrColorsChoice1)
        else
            ScreenBuffer.Canvas.Draw(70, 105, PngScrColorsChoice2);

        for i := 0 to 7 do begin
          if not SelectedColors[Selecting].Contains(i) then begin
            PosX := 90 + (i Mod 4) * 126;
            PosY := 165 + (i div 4) * 120;
            ScreenBuffer.Canvas.Draw(PosX, PosY, PngBtnColors[i]);
          end;
        end;
      end;
  end;
  Canvas.Draw(0, 0, ScreenBuffer);
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.FormMouseDown(...)'}
procedure TfmMain.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Move form by click and drag from caption
  if (Y > 100) then
      exit;

  if Button = mbLeft then begin
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, $F012, 0);
    exit;
  end;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.FormClick(...)'}
procedure TfmMain.FormClick(Sender: TObject);
var
  i: Integer;
  p: TPoint;
begin
  if Page <> pgColors then
      exit;
  If InDemo then
      exit;
  p := CalcCursorPos;
  for i := 0 to 7 do begin
    if PtInRect(BtnRects[i], p) then begin
      SelectColor(i);
      exit;
    end;
  end;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.FormKeyPress(...)'}
procedure TfmMain.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Page <> pgColors then
      exit;
  if (Key < '1') or (Key > '8') then
      exit;
  SelectColor(StrToInt(Key) - 1);
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.MnuAboutClick'}
procedure TfmMain.MnuAboutClick(Sender: TObject);
begin
  ShowPage(pgAbout);
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.TextMenuClick'}
procedure TfmMain.TextMenuClick(Sender: TObject);
var
  Menu: TMenuItem;
  MenuName: string;
begin
  case (Sender as TMenuItem).MenuIndex of
    0: LongText.Text := TextHelpUse;
    1: LongText.Text := TextHelpIntro;
    2: LongText.Text := TextHelpImportant;
    3: LongText.Text := TextHelpNotes;
  end;
  ShowPage(pgText);
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.edtNameKeyPress'}
procedure TfmMain.edtNameKeyPress(Sender: TObject; var Key: Char);
var
  Itemp: Integer;
  IString: string;
begin
  If InDemo then begin
    Key := #0;
    exit;
  end;
  if Key <> #13 then
      exit;
  if Length(edtName.Text) < 3 then begin
    ShowMessage('حد اقل ۳ حرف وارد کنید');
    exit;
  end;
  ShowPage(pgColors);
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnArchiveClick(...)'}
procedure TfmMain.BtnArchiveClick(Sender: TObject);
begin
  ShowPage(pgArchive);
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnBackClick(...)'}
procedure TfmMain.BtnBackClick(Sender: TObject);
begin
  ShowPage(pgHome);
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnDemoClick(...)'}
procedure TfmMain.BtnDemoClick(Sender: TObject);
var
  i, j: Integer;
const
  username = 'Demo';
  selection: array [0 .. 1] of string = ('12037465', '03741625');
begin
  PlaySound(SndClick);

  InDemo := True;
  ShowPage(pgNameEntry);
  Application.ProcessMessages;
  Sleep(500);
  if not InDemo then
      exit;
  for i := 1 to StrLen(username) do begin
    edtName.SelText := username[i];
    PlaySound(SndClick);
    Application.ProcessMessages;
    Sleep(300);
    if not InDemo then
        exit;
  end;
  PlaySound(SndExit, SND_NODEFAULT or SND_SYNC);
  ShowPage(pgColors);
  Application.ProcessMessages;
  Sleep(1000);
  if not InDemo then
      exit;

  for j := 0 to 1 do begin
    Selecting := j;
    for i := 1 to 8 do begin
      PlaySound(SndShatter);
      SelectedColors[j].Add(StrToInt(selection[j][i]));
      Invalidate();
      Application.ProcessMessages;
      Sleep(800);
    end;
    Invalidate();
    Application.ProcessMessages;
    Sleep(1000);
    PlaySound(SndExit, SND_NODEFAULT or SND_SYNC);
    Sleep(500);
  end;

  ProcessColors;
  ShowPage(pgText);
  Application.ProcessMessages;
  Sleep(2000);
  PlaySound(SndExit, SND_NODEFAULT or SND_SYNC);
  ShowPage(pgHome);
  InDemo := false;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnExitClick(...)'}
procedure TfmMain.BtnExitClick(Sender: TObject);
begin
  PlaySound(SndExit, SND_NODEFAULT or SND_SYNC);
  Close;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnLadyBugClick(...)'}
procedure TfmMain.BtnLadyBugClick(Sender: TObject);
begin
  HelpMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnPrintClick(...)'}
procedure TfmMain.BtnPrintClick(Sender: TObject);
begin

end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnRunClick(...)'}
procedure TfmMain.BtnRunClick(Sender: TObject);
begin
  ShowPage(pgNameEntry);
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnDeleteClick(...)'}
procedure TfmMain.BtnDeleteClick(Sender: TObject);
begin
  if lstNames.ItemIndex > -1 then begin
    // ColorList.Items.Delete(Index);
    lstNames.Items.Delete(lstNames.ItemIndex);
    SaveHistory;
    LoadHistory;
    if (lstNames.ItemIndex > -1) then
        lstNames.ItemIndex := 0;
  end;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BtnViewClick(...)'}
procedure TfmMain.BtnViewClick(Sender: TObject);
var
  i: Integer;
  chunks: TArray<string>;
begin
  if lstNames.ItemIndex < 0 then
      exit;
  try
    chunks := lstNames.Items[lstNames.ItemIndex].Split([#9]);
    for i := 1 to 8 do begin
      SelectedColors[0].Add(StrToInt(chunks[2][i]));
      SelectedColors[1].Add(StrToInt(chunks[3][i]));
    end;
    ProcessColors;
    ShowPage(pgText);
    Invalidate;
  except
      ShowMessage('Corrupted save file');
  end;

end;
{$ENDREGION}

{$REGION 'procedure TMainForm.BuildForm'}
procedure TfmMain.BuildForm;
var
  LstTabs: array [0 .. 1] of Integer;
begin
  BtnRun := TPngImageShadowButton.Create(Self);
  With BtnRun do begin
    parent := Self;
    top := 129;
    left := 74;
    Image := LoadPng('btn_run');
    ShadowImage := LoadPng('btn_run_shade');
    OnClick := BtnRunClick;
  end;

  BtnDemo := TPngImageShadowButton.Create(Self);
  With BtnDemo do begin
    parent := Self;
    top := 139;
    left := 314;
    Image := LoadPng('btn_demo');
    ShadowImage := LoadPng('btn_demo_shade');
    OnClick := BtnDemoClick;
  end;

  BtnArchive := TPngImageShadowButton.Create(Self);
  With BtnArchive do begin
    parent := Self;
    top := 269;
    left := 194;
    Image := LoadPng('btn_archive');
    ShadowImage := LoadPng('btn_archive_shade');
    OnClick := BtnArchiveClick;
  end;

  BtnExit := TPngImageShadowButton.Create(Self);
  With BtnExit do begin
    parent := Self;
    top := 259;
    left := 414;
    Image := LoadPng('btn_exit');
    ShadowImage := LoadPng('btn_exit_shade');
    OnClick := BtnExitClick;
  end;

  BtnView := TPngImageShadowButton.Create(Self);
  With BtnView do begin
    parent := Self;
    top := 137;
    left := 310;
    Image := LoadPng('btn_view');
    ShadowImage := LoadPng('btn_view_shade');
    OnClick := BtnViewClick;
    Visible := false;
  end;

  BtnDelete := TPngImageShadowButton.Create(Self);
  With BtnDelete do begin
    parent := Self;
    top := 233;
    left := 415;
    Image := LoadPng('btn_delete');
    ShadowImage := LoadPng('btn_delete_shade');
    OnClick := BtnDeleteClick;
    Visible := false;
  end;

  BtnLadyBug := TPngImageShadowButton.Create(Self);
  With BtnLadyBug do begin
    parent := Self;
    top := 375;
    left := 58;
    Image := LoadPng('btn_ladybug');
    ShadowImage := LoadPng('btn_ladybug_shade');
    ShadowOffset := TPoint.Create(2, 2);
    PressedOffset := TPoint.Create(2, 2);
    HoverOffset := TPoint.Create(1, 1);
    OnClick := BtnLadyBugClick;
  end;

  BtnBack := TPngImageButton.Create(Self);
  with BtnBack do begin
    parent := Self;
    Visible := True;
    top := 391;
    left := 506;
    NormalImage := LoadPng('btn_back_np');
    HoverImage := LoadPng('btn_back_up');
    DownImage := LoadPng('btn_back_dn');
    OnClick := BtnBackClick;
    Visible := false;
  end;

  BtnPrint := TPngImageButton.Create(Self);
  with BtnPrint do begin
    parent := Self;
    Visible := True;
    top := 391;
    left := 427;
    NormalImage := LoadPng('btn_print_np');
    HoverImage := LoadPng('btn_print_up');
    DownImage := LoadPng('btn_print_dn');
    OnClick := BtnPrintClick;
    Visible := false;
  end;

  ColorList := TListBox.Create(Self);
  with ColorList do begin
    parent := Self;
    left := 5;
    top := 5;
    Width := 209;
    Height := 33;
    ItemHeight := 13;
    TabOrder := 0;
    Visible := false;
  end;

  edtName := TEdit.Create(Self);
  with edtName do begin
    parent := Self;
    left := 77;
    top := 283;
    Width := 475;
    Height := 66;
    AutoSize := false;
    BorderStyle := bsNone;
    Color := 16232311;
    Ctl3D := false;
    Font.Height := -47;
    Font.Style := [fsBold];
    MaxLength := 10;
    OnKeyPress := edtNameKeyPress;
    Visible := false;
  end;

  LstTabs[0] := 42;
  LstTabs[1] := 120;
  lstNames := TListBox.Create(Self);
  with lstNames do begin
    parent := Self;
    left := 65;
    top := 131;
    Width := 200;
    Height := 223;
    BiDiMode := bdLeftToRight;
    BorderStyle := bsNone;
    Font.Name := 'Tahoma';
    ExtendedSelect := false;
    Font.Color := clNavy;
    Font.Height := -14;
    Font.Style := [fsBold];
    ItemHeight := 19;
    ParentBiDiMode := false;
    Visible := false;
    TabWidth := 1;
    SendMessage(Handle, LB_SETTABSTOPS, High(LstTabs), NativeUInt(@LstTabs));
  end;

  LongText := TMemo.Create(Self);
  with LongText do begin
    parent := Self;
    left := 67;
    top := 120;
    Width := 497;
    Height := 238;
    BorderStyle := bsNone;
    Color := 16232311;
    Font.Height := -24;
    Font.Style := [];
    ReadOnly := True;
    ScrollBars := ssVertical;
    Visible := false;
  end;

  // Create HelpMenu
  MnuHelpUse := TMenuItem.Create(Self);
  MnuHelpUse.Caption := 'روش استفاده';
  MnuHelpUse.ShortCut := 0;
  MnuHelpUse.OnClick := TextMenuClick;

  MnuIntro := TMenuItem.Create(Self);
  MnuIntro.Caption := 'مقدمــــــــــه';
  MnuIntro.OnClick := TextMenuClick;

  MnuNote := TMenuItem.Create(Self);
  MnuNote.Caption := 'اصول آزمايش';
  MnuNote.OnClick := TextMenuClick;

  MnuImportant := TMenuItem.Create(Self);
  MnuImportant.Caption := 'نكات مهــــــم';
  MnuImportant.OnClick := TextMenuClick;

  MnuLine := TMenuItem.Create(Self);
  MnuLine.Caption := '-';

  MnuAbout := TMenuItem.Create(Self);
  MnuAbout.Caption := 'دربــــــــــــاره';
  MnuAbout.OnClick := MnuAboutClick;

  HelpMenu := TPopupMenu.Create(Self);
  with HelpMenu do begin
    AutoHotKeys := maManual;
    Items.Add(MnuHelpUse);
    Items.Add(MnuIntro);
    Items.Add(MnuNote);
    Items.Add(MnuImportant);
    Items.Add(MnuLine);
    Items.Add(MnuAbout);
  end;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.BuildColorScreen'}
procedure TfmMain.BuildColorScreen;
var
  bitmap: TBitmap;
  png1: TPngImage;
  png2: TPngImage;
  i, j: Integer;
  SrcTop, SrcLeft: Integer;
  DestTop, DestLeft: Integer;
begin
  bitmap := TBitmap.Create;
  bitmap.Width := 500;
  bitmap.Height := 275;
  bitmap.Canvas.Brush.Style := bsSolid;
  bitmap.Canvas.Brush.Color := RGB($77, $AF, $F7);
  bitmap.Canvas.FillRect(rect(0, 0, bitmap.Width, bitmap.Height));

  png2 := LoadPng('scr_color_header');
  bitmap.Canvas.Draw(0, 0, png2);
  png1 := LoadPng('btn_colors');
  png2 := LoadPng('btn_color_frame');
  for i := 0 to 7 do begin
    DestLeft := 20 + (i Mod 4) * 126;
    DestTop := 60 + (i div 4) * 120;
    SrcLeft := (i Mod 4) * 80;
    SrcTop := (i div 4) * 80;
    bitmap.Canvas.CopyRect(rect(DestLeft, DestTop, DestLeft + 80, DestTop + 80), png1.Canvas, rect(SrcLeft, SrcTop, SrcLeft + 80, SrcTop + 80));
    // 70 and 105 are the top left corner of color selection screen in relation to form
    BtnRects[i] := rect(70 + DestLeft, 105 + DestTop, 70 + DestLeft + 80, 105 + DestTop + 80);
    bitmap.Canvas.Draw(DestLeft - 10, DestTop - 10, png2);
  end;

  png2 := LoadPng('scr_color_caption_first');
  PngScrColorsChoice1 := TPngImage.Create();
  PngScrColorsChoice1.Assign(bitmap);
  PngScrColorsChoice1.Canvas.Draw(195, 5, png2);
  // PngScrColorsChoice1.SaveToFile('.\choice1.png');

  png2 := LoadPng('scr_color_caption_second');
  PngScrColorsChoice2 := TPngImage.Create();
  PngScrColorsChoice2.Assign(bitmap);
  PngScrColorsChoice2.Canvas.Draw(195, 5, png2);
  // PngScrColorsChoice1.SaveToFile('.\choice2.png');

  png2 := LoadPng('btn_color_frame');
  for i := 0 to 7 do begin
    PngBtnColors[i] := TPngImage.Create();
    bitmap.Width := 80;
    bitmap.Height := 80;
    bitmap.Canvas.Brush.Color := Colors[i];
    bitmap.Canvas.FillRect(rect(0, 0, bitmap.Width, bitmap.Height));
    bitmap.Canvas.Draw(-10, -10, png2);
    PngBtnColors[i].Assign(bitmap);
    // PngBtnColors[I].SaveToFile('.\color' + IntToStr(I) + '.png');
  end;

end;
{$ENDREGION}

{$REGION 'procedure TMainForm.LoadResources'}
procedure TfmMain.LoadResources;
var
  tempText: string;
  tempLine: string;
  chunks: TArray<string>;
begin
  PngScrAbout := LoadPng('scr_about');
  PngScrBg := LoadPng('scr_bg');
  PngScrEnterName := LoadPng('scr_enter_name');
  PngScrResultBox := LoadPng('scr_result_box');
  PngScrScrolls := LoadPng('scr_scrolls');
  // PngBtnColors := LoadPng('btn_colors');

  SndStart := LoadSound('SND_START');
  SndClick := LoadSound('SND_CLICK');
  SndExit := LoadSound('SND_CLICK1');
  SndShatter := LoadSound('SND_CLICK2');

  TextHelpIntro := decrypt(LoadText('HELP_INTRO'), pass);
  TextHelpNotes := decrypt(LoadText('HELP_NOTES'), pass);
  TextHelpUse := decrypt(LoadText('HELP_USE'), pass);
  TextHelpImportant := decrypt(LoadText('HELP_IMPORTANT'), pass);

  tempText := decrypt(LoadText('TEXT_COLOR_CODES'), pass);
  ColorCodes := TDictionary<string, string>.Create;
  for tempLine in tempText.Split([#10]) do begin
    chunks := tempLine.Split([';']);
    ColorCodes.Add(chunks[0], ReplaceStr(chunks[1], '\n', #13#10));
  end;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.UnloadResources'}
procedure TfmMain.UnloadResources;
begin
  // Free images
  PngScrAbout.Free;
  PngScrBg.Free;
  PngScrEnterName.Free;
  PngScrResultBox.Free;
  PngScrScrolls.Free;

  // PngBtnColors.Free;

  // Free font memory
  UnloadFont;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.PlaySound(...)'}
procedure TfmMain.PlaySound(SoundPointer: pointer; Options: Integer = SND_NODEFAULT or SND_ASYNC);
begin
  if (nosound) then
      exit;
  sndPlaySound(SoundPointer, SND_MEMORY or Options);
end;
{$ENDREGION}

{$REGION 'function TMainForm.LoadSound(...): pointer;'}
function TfmMain.LoadSound(Name: string): pointer;
var
  p: pointer;
begin
  p := pointer(FindResource(hInstance, PChar(Name), 'WAVE'));
  if p <> nil then begin
    p := pointer(LoadResource(hInstance, HRSRC(p)));
    if p <> nil then
        p := LockResource(HGLOBAL(p));
  end;
  result := p;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.LoadFont'}
procedure TfmMain.LoadFont;
var
  RS: TResourceStream;
  FontsCount: DWORD;
begin
  try
    RS := TResourceStream.Create(hInstance, 'b_tabassom', 'TTF');
    MemBTabssom := AddFontMemResourceEx(RS.Memory, RS.Size, nil, @FontsCount);
    Self.Font.Name := 'b tabassom';
    RS.Free;
  except
  end;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.UnloadFont'}
procedure TfmMain.UnloadFont;
begin
  try
      RemoveFontMemResourceEx(MemBTabssom);
  except
  end;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.LoadPng(...)'}
function TfmMain.LoadPng(Name: string): TPngImage;
var
  ResStream: TResourceStream;
begin
  try
    result := TPngImage.Create;
    result.Transparent := True;
    // PngImage component will not load image from any resource group other than RCDATA since it is hardcoded by an idiot in component code.
    // Result.LoadFromResourceName(hInstance, Name);
    ResStream := TResourceStream.Create(hInstance, Name, 'PNG');
    result.LoadFromStream(ResStream);
    ResStream.Free;
  except
      raise Exception.Create('The png image ' + Name + ' could not be loaded.');
  end;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.LoadText(...)'}
function TfmMain.LoadText(Name: string): string;
var
  ResStream: TResourceStream;
  str: TStringList;
begin
  try
    ResStream := TResourceStream.Create(hInstance, Name, 'TEXT');
    str := TStringList.Create;
    str.LoadFromStream(ResStream);
    result := str.Text;
    ResStream.Free;
  except
      raise Exception.Create('Text ' + Name + ' could not be loaded.');
  end;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.ShowPage(...)'}
procedure TfmMain.ShowPage(APage: TPageName);
begin
  Page := APage;

  BtnRun.Visible := Page = pgHome;
  BtnDemo.Visible := Page = pgHome;
  BtnArchive.Visible := Page = pgHome;
  BtnExit.Visible := Page = pgHome;

  BtnBack.Visible := Page in [pgNameEntry, pgArchive, pgText, pgAbout, pgColors];
  // BtnPrint.Visible := Page = pgText;
  edtName.Visible := Page = pgNameEntry;
  BtnView.Visible := Page = pgArchive;
  BtnDelete.Visible := Page = pgArchive;

  BtnLadyBug.Visible := Page <> pgArchive;

  edtName.Visible := Page = pgNameEntry;
  lstNames.Visible := Page = pgArchive;
  LongText.Visible := Page = pgText;

  if (Page = pgNameEntry) then begin
    edtName.Text := '';
    edtName.SetFocus;
  end;

  if (Page = pgHome) then
      ResetVars;

  Invalidate;
end;
{$ENDREGION}

{$REGION 'procedure TmainForm.ResetVars;'}
procedure TfmMain.ResetVars;
begin
  Selecting := 0;
  SelectedColors[0] := TList<Integer>.Create;
  SelectedColors[1] := TList<Integer>.Create;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.ShowNameEntry'}
procedure TfmMain.ShowNameEntry;
begin

end;
{$ENDREGION}

{$REGION 'procedure TfmMain.SelectColor(...)'}
procedure TfmMain.SelectColor(ColorIndex: Integer);
var
  SaveItem: string;
  i: Integer;
begin
  if Page <> pgColors then
      exit;
  If InDemo then
      exit;

  if not SelectedColors[Selecting].Contains(ColorIndex) then begin
    PlaySound(SndShatter);
    SelectedColors[Selecting].Add(ColorIndex);
    Invalidate;
  end;
  if SelectedColors[Selecting].Count >= 8 then begin
    inc(Selecting);
    if Selecting > 1 then begin
      PlaySound(SndClick);
      ShowPage(pgText);

      SaveItem := edtName.Text + #09 + FormatDateTime('yyyy-mm-dd hh:mm:ss', Now) + #09;
      for i := 0 to 7 do
          SaveItem := SaveItem + IntToStr(SelectedColors[0][i]);
      SaveItem := SaveItem + #09;
      for i := 0 to 7 do
          SaveItem := SaveItem + IntToStr(SelectedColors[0][i]);
      lstNames.Items.Insert(0, SaveItem);
      ProcessColors;
    end;
    Invalidate;
  end;
end;
{$ENDREGION}

{$REGION 'procedure TfmMain.ProcessColors'}
procedure TfmMain.ProcessColors;
var
  Sign: string;
  Messages, j: Integer;
  Item: TPair<string, string>;
begin
  for j := 0 to 6 do begin
    case j div 2 of
      0: Sign := '+';
      2: Sign := '*';
      4: Sign := '=';
      6: Sign := '-';
    end;
    for Item in ColorCodes do
      if Sign + IntToStr(SelectedColors[0][j]) + Sign + IntToStr(SelectedColors[0][j + 1]) = Item.Key then
          LongText.Lines.Add(Item.Value + #13#10);
    if (SelectedColors[0][j] = SelectedColors[1][j]) and (SelectedColors[0][j + 1] = SelectedColors[1][j + 1]) then
        continue;
    for Item in ColorCodes do
      if Sign + IntToStr(SelectedColors[1][j]) + Sign + IntToStr(SelectedColors[1][j + 1]) = Item.Key then
          LongText.Lines.Add(Item.Value + #13#10);
  end;

  for Item in ColorCodes do
    if '+' + IntToStr(SelectedColors[0][1]) + '-' + IntToStr(SelectedColors[0][7]) = Item.Key then
        LongText.Lines.Add(Item.Value + #13#10);
  if (SelectedColors[0][0] <> SelectedColors[1][0]) or (SelectedColors[0][7] <> SelectedColors[1][7]) then
    for Item in ColorCodes do
      if '+' + IntToStr(SelectedColors[1][1]) + '-' + IntToStr(SelectedColors[1][7]) = Item.Key then
          LongText.Lines.Add(Item.Value + #13#10);
  // force memo to scroll back up
  LongText.SelStart := 0;
  LongText.SelLength := 0;
  LongText.ClearSelection;

  ShowPage(pgText);
  LongText.SetFocus;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.SaveHistory'}
procedure TfmMain.SaveHistory;
var
  FileName: string;
begin
  FileName := TPath.GetDirectoryName(Application.ExeName) + '\' + TPath.GetFileNameWithoutExtension(Application.ExeName) + '.sav';
  try
      lstNames.Items.SaveToFile(FileName);
  except
  end;
end;
{$ENDREGION}

{$REGION 'procedure TMainForm.LoadHistory'}
procedure TfmMain.LoadHistory;
var
  FileName: string;
begin
  try
    FileName := TPath.GetDirectoryName(Application.ExeName) + '\' + TPath.GetFileNameWithoutExtension(Application.ExeName) + '.sav';
    if FileExists(FileName) then
        lstNames.Items.LoadFromFile(FileName);
  except
  end;
end;
{$ENDREGION}

end.
