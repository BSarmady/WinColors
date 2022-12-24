unit uPngImageShadowButton;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  uPngImageButton, ExtCtrls, StdCtrls, pngimage;

Type

  TPngImageShadowButton = class(TGraphicControl)
  private
    FOwner: TComponent;

    _Image: TPngImage;
    _ShadowImage: TPngImage;

    _NormalOffset: TPoint;
    _ShadowOffset: TPoint;
    _PressedOffset: TPoint;
    _HoverOffset: TPoint;

    FState: TPngImageButtonState;

    procedure SetImage(const Value: TPngImage);
    procedure SetShadowImage(const Value: TPngImage);

    procedure SetShadowOffset(const Value: TPoint);
    procedure SetHoverOffset(const Value: TPoint);
    procedure SetPressedOffset(const Value: TPoint);

    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMLBUTTONDOWN(var Message: TMessage); message WM_LBUTTONDOWN;
    procedure WMLBUTTONUP(var Message: TMessage); message WM_LBUTTONUP;

    procedure ReCalculate;
    function GetNormalOffset: TPoint;
    function GetHoverOffset: TPoint;
    function GetPressedOffset: TPoint;
    function GetShadowOffset: TPoint;

  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; Override;
  published

    property Image: TPngImage read _Image Write SetImage;
    property ShadowImage: TPngImage read _ShadowImage Write SetShadowImage;

    property NormalOffset: TPoint read GetNormalOffset;
    property ShadowOffset: TPoint read GetShadowOffset Write SetShadowOffset;
    property HoverOffset: TPoint read GetHoverOffset Write SetHoverOffset;
    property PressedOffset: TPoint read GetPressedOffset Write SetPressedOffset;
    property OnClick;
  End;

  // procedure Register;

implementation

{$REGION 'procedure TPngImageShadowButton.ReCalculate'}
procedure TPngImageShadowButton.ReCalculate;
var
  W, H: Integer;
  _GlobalCoord: TPoint;
begin

  // Calculate smallest point of all states to set as base of xy axis
  _GlobalCoord := TPoint.Create(0, 0);
  _NormalOffset := TPoint.Create(0, 0);
  if (_GlobalCoord.X > ShadowOffset.X) then
    _GlobalCoord.X := ShadowOffset.X;
  if (_GlobalCoord.X > ShadowOffset.X) then
    _GlobalCoord.X := ShadowOffset.X;

  if (_GlobalCoord.X > HoverOffset.X) then
    _GlobalCoord.X := HoverOffset.X;
  if (_GlobalCoord.X > PressedOffset.X) then
    _GlobalCoord.X := PressedOffset.X;

  if (_GlobalCoord.Y > PressedOffset.Y) then
    _GlobalCoord.Y := PressedOffset.Y;
  if (_GlobalCoord.Y > PressedOffset.Y) then
    _GlobalCoord.Y := PressedOffset.Y;

  _NormalOffset := _NormalOffset.Subtract(_GlobalCoord);
  _ShadowOffset := _ShadowOffset.Subtract(_GlobalCoord);
  _PressedOffset := _PressedOffset.Subtract(_GlobalCoord);
  _HoverOffset := _HoverOffset.Subtract(_GlobalCoord);

  // Find largest image width/height necessary to fit entire button image in any state
  // We only need largest image size + disposition to find calculate max width/height of image to show entire button image in any state
  W := Self.Width;
  H := Self.Height;
  if (_Image <> nil) Then begin

    if (W < _Image.Width + _NormalOffset.X) then
      W := _Image.Width + _NormalOffset.X;
    if (W < _Image.Width + _PressedOffset.X) then
      W := _Image.Width + _PressedOffset.X;
    if (W < _Image.Width + _HoverOffset.X) then
      W := _Image.Width + _HoverOffset.X;

    if (H < _Image.Height + _NormalOffset.Y) then
      H := _Image.Height + _NormalOffset.Y;
    if (H < _Image.Height + _PressedOffset.Y) then
      H := _Image.Height + _PressedOffset.Y;
    if (H < _Image.Height + _HoverOffset.Y) then
      H := _Image.Height + _HoverOffset.Y;
  end;
  if (_ShadowImage <> nil) Then begin
    if (W < _ShadowImage.Width + _ShadowOffset.X) then
      W := _ShadowImage.Width + _ShadowOffset.X;
    if (H < _ShadowImage.Height + _ShadowOffset.X) then
      H := _ShadowImage.Height + _ShadowOffset.X;
  end;

  Width := W;
  Height := H;
  invalidate;
end;
{$ENDREGION}

{$REGION 'Constructor TPngImageShadowButton.Create(...)'}
Constructor TPngImageShadowButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOwner := AOwner;
  _Image := TPngImage.Create;
  _ShadowImage := TPngImage.Create;

  _ShadowOffset := TPoint.Create(4, 4);
  _PressedOffset := TPoint.Create(4, 4);
  _HoverOffset := TPoint.Create(2, 2);

  FState := Normal;
end;
{$ENDREGION}

{$REGION 'Destructor TPngImageShadowButton.Destroy'}
Destructor TPngImageShadowButton.Destroy;
begin
  if (Assigned(_Image)) then
    _Image.Free;
  if (Assigned(_ShadowImage)) then
    _ShadowImage.Free;
  inherited Destroy;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.Paint'}
procedure TPngImageShadowButton.Paint;
begin
  inherited;

  if Assigned(_ShadowImage) then
    Canvas.Draw(_ShadowOffset.X, _ShadowOffset.Y, _ShadowImage);

  case FState of
    Normal:
      if Assigned(_Image) then
        Canvas.Draw(_NormalOffset.X, _NormalOffset.Y, _Image);
    Hover:
      if Assigned(_Image) then
        Canvas.Draw(_HoverOffset.X, _HoverOffset.Y, _Image);
    Pressed:
      if Assigned(_Image) then
        Canvas.Draw(_PressedOffset.X, _PressedOffset.Y, _Image);
  end;
end;
{$ENDREGION}

{$REGION'PROCEDURE TPngImageShadowButton.WMLBUTTONDOWN(...)'}
procedure TPngImageShadowButton.WMLBUTTONDOWN(var Message: TMessage);
begin
  inherited;
  FState := Pressed;
  invalidate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.WMLBUTTONUP(...)'}
procedure TPngImageShadowButton.WMLBUTTONUP(var Message: TMessage);
begin
  inherited;
  FState := Hover;
  invalidate;
end;
{$ENDREGION}

{$REGION 'Procedure TPngImageShadowButton.CMMouseEnter(...)'}
Procedure TPngImageShadowButton.CMMouseEnter(var Message: TMessage);
Begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FState := Hover;
  invalidate;
end;
{$ENDREGION}

{$REGION 'Procedure TPngImageShadowButton.CMMouseLeave(...)'}
Procedure TPngImageShadowButton.CMMouseLeave(var Message: TMessage);
Begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  FState := Normal;
  invalidate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.SetImage(...)'}
procedure TPngImageShadowButton.SetImage(const Value: TPngImage);
begin
  _Image := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.SetPressedImage(...)'}
procedure TPngImageShadowButton.SetShadowImage(const Value: TPngImage);
begin
  _ShadowImage := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.SetShadowOffset(...)'}
procedure TPngImageShadowButton.SetShadowOffset(const Value: TPoint);
begin
  _ShadowOffset := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.SetHoverOffset(...)'}
procedure TPngImageShadowButton.SetHoverOffset(const Value: TPoint);
begin
  _HoverOffset := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'procedure TPngImageShadowButton.SetPressedOffset(...)'}
procedure TPngImageShadowButton.SetPressedOffset(const Value: TPoint);
begin
  _PressedOffset := Value;
  ReCalculate;
end;
{$ENDREGION}

{$REGION 'function TPngImageShadowButton.GetNormalOffset: TPoint;'}
function TPngImageShadowButton.GetNormalOffset: TPoint;
begin
  Result := TPoint.Create(0, 0);
end;

{$ENDREGION}

{$REGION 'function TPngImageShadowButton.GetHoverOffset: TPoint;'}
function TPngImageShadowButton.GetHoverOffset: TPoint;
begin
  Result := _HoverOffset.Add(_NormalOffset);
end;
{$ENDREGION}

{$REGION 'function TPngImageShadowButton.GetPressedOffset: TPoint;'}
function TPngImageShadowButton.GetPressedOffset: TPoint;
begin
  Result := _PressedOffset.Add(_NormalOffset);
end;
{$ENDREGION}

{$REGION 'function TPngImageShadowButton.GetShadowOffset: TPoint;'}
function TPngImageShadowButton.GetShadowOffset: TPoint;
begin
  Result := _ShadowOffset.Subtract(_NormalOffset);
end;
{$ENDREGION}

{$REGION 'procedure Register'}
{
  procedure Register;
  begin
  RegisterComponents('JGhost', [TPngImageShadowButton])
  end;
}
{$ENDREGION}

end.
