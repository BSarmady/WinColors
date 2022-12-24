unit uPngImageButton;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  ExtCtrls, StdCtrls, pngimage;

Type

  TPngImageButtonState = (Hover, Normal, Pressed);

  TPngImageButton = class(TGraphicControl)
  private
    FOwner: TComponent;

    _NormalImage: TPngImage;
    _HoverImage: TPngImage;
    _PressedImage: TPngImage;

    FState: TPngImageButtonState;

    procedure SetNormalImage(const Value: TPngImage);
    procedure SetHoverImage(const Value: TPngImage);
    procedure SetPressedImage(const Value: TPngImage);

    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMLBUTTONDOWN(var Message: TMessage); message WM_LBUTTONDOWN;
    procedure WMLBUTTONUP(var Message: TMessage); message WM_LBUTTONUP;

    procedure ReCalculate;

    procedure Click; override;

  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; Override;
  published

    property DownImage: TPngImage read _PressedImage Write SetPressedImage;
    property HoverImage: TPngImage read _HoverImage Write SetHoverImage;
    property NormalImage: TPngImage read _NormalImage Write SetNormalImage;

    property OnClick;
  End;

  // procedure Register;

implementation

{$REGION 'procedure TPngImageButton.ReCalculate'}
procedure TPngImageButton.ReCalculate;
var
  W, H: Integer;
begin
  W := Self.Width;
  H := Self.Height;

  if (_NormalImage <> nil) Then begin
    if (W < _NormalImage.Width) then
      W := _NormalImage.Width;
    if (H < _NormalImage.Height) then
      H := _NormalImage.Height;
  end;
  if (_PressedImage <> nil) Then begin
    if (W < _PressedImage.Width) then
      W := _PressedImage.Width;
    if (H < _PressedImage.Height) then
      H := _PressedImage.Height;
  end;
  if (_HoverImage <> nil) Then begin
    if (W < _HoverImage.Width) then
      W := _HoverImage.Width;
    if (H < _HoverImage.Height) then
      H := _HoverImage.Height;
  end;
  Self.Width := W;
  Self.Height := H;
  invalidate;
end;
{$ENDREGION}

{$REGION 'Constructor TPngImageButton.Create(...)'}
Constructor TPngImageButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOwner := AOwner;
  _NormalImage := TPngImage.Create;
  _HoverImage := TPngImage.Create;
  _PressedImage := TPngImage.Create;
  FState := Normal;
  //Scale by DPI
  Width := 64;
  Height := 64;

end;
{$ENDREGION}

{$REGION 'Destructor TPngImageButton.Destroy'}
Destructor TPngImageButton.Destroy;
begin
  if (Assigned(_NormalImage)) then
    _NormalImage.Free;
  if (Assigned(_HoverImage)) then
    _HoverImage.Free;
  if (Assigned(_PressedImage)) then
    _PressedImage.Free;
  inherited Destroy;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageButton.Paint'}
procedure TPngImageButton.Paint;
begin
  inherited;

  case FState of
    Normal:
      if Assigned(_NormalImage) then
        Canvas.Draw(0, 0, _NormalImage);
    Hover:
      if Assigned(_HoverImage) then
        Canvas.Draw(0, 0, _HoverImage);
    Pressed:
      if Assigned(_PressedImage) then
        Canvas.Draw(0, 0, _PressedImage);
  else
    Canvas.Rectangle(0, 0, Width, Height);
  end;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageButton.SetNormalImage(...)'}
procedure TPngImageButton.SetNormalImage(const Value: TPngImage);
begin
  _NormalImage := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageButton.SetPressedImage(...)'}
procedure TPngImageButton.SetPressedImage(const Value: TPngImage);
begin
  _PressedImage := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageButton.SetHoverImage(...)'}
procedure TPngImageButton.SetHoverImage(const Value: TPngImage);
begin
  _HoverImage := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION'PROCEDURE TPngImageButton.WMLBUTTONDOWN(...)'}
procedure TPngImageButton.WMLBUTTONDOWN(var Message: TMessage);
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FState := Pressed;
  invalidate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageButton.WMLBUTTONUP(...)'}
procedure TPngImageButton.WMLBUTTONUP(var Message: TMessage);
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FState := Hover;
  invalidate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageButton.Click'}
procedure TPngImageButton.Click;
begin
  inherited;

end;
{$ENDREGION}

{$REGION 'Procedure TPngImageButton.CMMouseEnter(...)'}
Procedure TPngImageButton.CMMouseEnter(var Message: TMessage);
Begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FState := Hover;
  invalidate;
end;
{$ENDREGION}

{$REGION 'Procedure TPngImageButton.CMMouseLeave(...)'}
Procedure TPngImageButton.CMMouseLeave(var Message: TMessage);
Begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FState := Normal;
  invalidate;
end;
{$ENDREGION}

{$REGION 'procedure Register'}
{
  procedure Register;
  begin
  RegisterComponents('JGhost', [TPngImageButton])
  end;
}
{$ENDREGION}

end.
