unit uRegistry;

interface

uses
  Windows, Forms, Classes, SysUtils, Dialogs, Registry, StrUtils;

procedure Write_MULTI_SZ(const Subkey, ValueName: string; Strings: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);
procedure Read_MULTI_SZ(const Subkey, ValueName: string; Strings: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);

procedure LoadFormState(aForm: TForm; RegRoot: string; RootKey: HKey = HKEY_CURRENT_USER);
procedure SaveFormState(aForm: TForm; RegRoot: string; RootKey: HKey = HKEY_CURRENT_USER);

function SaveToRegistry(KeyName: String; ValueName: string; Value: string; const RootKey: HKey = HKEY_CURRENT_USER): Boolean; overload;
function SaveToRegistry(KeyName: String; ValueName: string; Value: Integer; const RootKey: HKey = HKEY_CURRENT_USER): Boolean; overload;
function SaveToRegistry(KeyName: String; ValueName: string; Value: Boolean; const RootKey: HKey = HKEY_CURRENT_USER): Boolean; overload;
function SaveToRegistry(KeyName: String; ValueName: string; Value: Double; const RootKey: HKey = HKEY_CURRENT_USER): Boolean; overload;

function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: String; const RootKey: HKey = HKEY_CURRENT_USER): String; overload;
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: Integer; const RootKey: HKey = HKEY_CURRENT_USER): Integer; overload;
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: Boolean; const RootKey: HKey = HKEY_CURRENT_USER): Boolean; overload;
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: Double; const RootKey: HKey = HKEY_CURRENT_USER): Double; overload;

function DeleteRegistryKey(KeyName: String; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
function DeleteRegistryValue(KeyName: String; ValueName: string; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;

procedure LoadRegistryKeys(KeyName: String; KeyList: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);

implementation

type
{$REGION 'DEF record TWindowPos'}
  TWindowPos = record
    Top, Left, Width, Height: Integer;
    State: TWindowState;
  end;
{$ENDREGION}

{$REGION 'procedure LoadFormState(aForm: TForm;RegRoot:string;RootKey:HKey = HKEY_CURRENT_USER);'}
procedure LoadFormState(aForm: TForm; RegRoot: string; RootKey: HKey = HKEY_CURRENT_USER);
var
  Registry: TRegistry;
  WindowPos: TWindowPos;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := RootKey;
    Registry.OpenKey(RegRoot, True);
    if aForm.WindowState = wsMinimized then
      aForm.WindowState := wsNormal;
    if Registry.ValueExists('WindowPos') then begin
      Registry.ReadBinaryData('WindowPos', WindowPos, SizeOf(WindowPos));

      if (aForm.BorderStyle = bsSizeable) then begin
        aForm.Width := WindowPos.Width;
        aForm.Height := WindowPos.Height;
      end;

      if (WindowPos.Top < Screen.DesktopHeight) then
        aForm.Top := WindowPos.Top
      else
        aForm.Top := Screen.DesktopHeight - aForm.Height;

      if (WindowPos.Top < 0) then
        aForm.Top := 0;

      if (WindowPos.Left < Screen.DesktopWidth) then
        aForm.Left := WindowPos.Left
      else
        aForm.Left := Screen.DesktopWidth - aForm.Width;

      if (WindowPos.Left < 0) then
        aForm.Left := 0;

      aForm.WindowState := WindowPos.State;
    end;
    Registry.CloseKey;
  finally
    Registry.Free;
  end;
end;
{$ENDREGION}

{$REGION 'procedure SaveFormState(aForm: TForm;RegRoot:string;RootKey:HKey = HKEY_CURRENT_USER);'}
procedure SaveFormState(aForm: TForm; RegRoot: string; RootKey: HKey = HKEY_CURRENT_USER);
var
  Registry: TRegistry;
  WindowPos: TWindowPos;
  WP: TWindowPlacement;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := RootKey;
    Registry.OpenKey(RegRoot, True);

    WindowPos.State := aForm.WindowState;
    aForm.WindowState := wsNormal;
    WindowPos.Top := aForm.Top;
    WindowPos.Left := aForm.Left;
    WindowPos.Width := aForm.Width;
    WindowPos.Height := aForm.Height;

    Registry.WriteBinaryData('WindowPos', WindowPos, SizeOf(WindowPos));
    Registry.CloseKey;
  finally
    Registry.Free;
  end;
end;
{$ENDREGION}

{$REGION 'procedure Read_MULTI_SZ(const Subkey, ValueName: string; Strings: TStrings;const RootKey: HKey = HKEY_CURRENT_USER);'}
procedure Read_MULTI_SZ(const Subkey, ValueName: string; Strings: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);
var
  Registry: TRegistry;
  BufferSize: Integer;
  TempStr: string;
  I: Integer;
begin
  Strings.Clear;
  Registry := TRegistry.Create;
  try
    Registry.RootKey := RootKey;
    if Registry.KeyExists(Subkey) then begin
      Registry.OpenKey(Subkey, False);
      if Registry.ValueExists(ValueName) then begin
        BufferSize := Registry.GetDataSize(ValueName);
        if BufferSize > 0 then begin
          SetLength(TempStr, BufferSize);
          Registry.ReadBinaryData(ValueName, TempStr[1], BufferSize);
          for I := 1 to Length(TempStr) do
            if TempStr[I] = #0 then
              TempStr[I] := #13;
          TempStr := LeftStr(TempStr, Length(TempStr) - 1);
          Strings.Text := StringReplace(TempStr, #13, #13#10, [rfReplaceAll]);
        end;
      end;
    end;
  finally
    FreeAndNil(Registry);
  end;
end;
{$ENDREGION}

{$REGION 'procedure Write_MULTI_SZ(const Subkey, ValueName: string; Strings: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);'}
procedure Write_MULTI_SZ(const Subkey, ValueName: string; Strings: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);
type
  pArray = ^TArray;
  TArray = array [0 .. 16383] of char;
var
  Registry: TRegistry;
  Result: Integer;
  Str: string;
begin
  Registry := TRegistry.Create;
  try
    Str := StringReplace(Strings.Text, #13#10, #0, [rfReplaceAll]);
    Str := Str + #0;
    Registry.RootKey := RootKey;
    if not Registry.OpenKey(Subkey, True) then
      raise Exception.Create('Can''t open key');
    Result := RegSetValueEx(Registry.CurrentKey, PChar(ValueName), 0, REG_MULTI_SZ, PChar(Str), Length(Str));
    if Result <> ERROR_SUCCESS then
      raise Exception.Create(SysErrorMessage(Result));
  finally
    FreeAndNil(Registry);
  end;
end;
{$ENDREGION}

{$REGION 'function SaveToRegistry(KeyName: String; ValueName:string; Value: string):Boolean;; const RootKey:HKey = HKEY_CURRENT_USER'}
// This function saves a string value to windows registry
function SaveToRegistry(KeyName: String; ValueName: string; Value: string; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, True);
      Registry.WriteString(ValueName, Value);
      Result := True;
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Write Errors
  end;
end;
{$ENDREGION}

{$REGION 'function SaveToRegistry(KeyName: String; ValueName:string; Value: Integer; const RootKey:HKey = HKEY_CURRENT_USER):Boolean;'}
// This funcitons saves an Integer value to windows registry
function SaveToRegistry(KeyName: String; ValueName: string; Value: Integer; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, True);
      Registry.WriteInteger(ValueName, Value);
      Result := True;
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Write Errors
  end;
end;
{$ENDREGION}

{$REGION 'function SaveToRegistry(KeyName: String; ValueName:string; Value: Boolean; const RootKey:HKey = HKEY_CURRENT_USER):Boolean;'}
// This funcitons saves a Boolean value to windows registry
function SaveToRegistry(KeyName: String; ValueName: string; Value: Boolean; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, True);
      Registry.WriteBool(ValueName, Value);
      Result := True;
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Write Errors
  end;
end;
{$ENDREGION}

{$REGION 'function SaveToRegistry(KeyName: String; ValueName:string; Value: Double; const RootKey:HKey = HKEY_CURRENT_USER):Boolean;'}
// This funcitons saves a Boolean value to windows registry
function SaveToRegistry(KeyName: String; ValueName: string; Value: Double; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, True);
      Registry.WriteFloat(ValueName, Value);
      Result := True;
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Write Errors
  end;
end;
{$ENDREGION}

{$REGION 'function LoadFromRegistry(KeyName: String; ValueName:string; DefaultValue: String; const RootKey:HKey = HKEY_CURRENT_USER):String;'}
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: String; const RootKey: HKey = HKEY_CURRENT_USER): String;
var
  Registry: TRegistry;
begin
  Result := DefaultValue;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, False);
      if Registry.ValueExists(ValueName) then
        Result := Registry.ReadString(ValueName);
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Read Errors
  end;
end;
{$ENDREGION}

{$REGION 'function LoadFromRegistry(KeyName: String; ValueName:string; DefaultValue: Integer; const RootKey:HKey = HKEY_CURRENT_USER):Integer;'}
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: Integer; const RootKey: HKey = HKEY_CURRENT_USER): Integer;
var
  Registry: TRegistry;
begin
  Result := DefaultValue;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, False);
      if Registry.ValueExists(ValueName) then
        Result := Registry.ReadInteger(ValueName);
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Read Errors
  end;
end;
{$ENDREGION}

{$REGION 'function LoadFromRegistry(KeyName: String; ValueName:string; DefaultValue: Boolean; const RootKey:HKey = HKEY_CURRENT_USER):Boolean;'}
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: Boolean; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := DefaultValue;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, False);
      if Registry.ValueExists(ValueName) then
        Result := Registry.ReadBool(ValueName);
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Read Errors
  end;
end;
{$ENDREGION}

{$REGION 'function LoadFromRegistry(KeyName: String; ValueName:string; DefaultValue: Double; const RootKey:HKey = HKEY_CURRENT_USER):Double;'}
function LoadFromRegistry(KeyName: String; ValueName: string; DefaultValue: Double; const RootKey: HKey = HKEY_CURRENT_USER): Double;
var
  Registry: TRegistry;
begin
  Result := DefaultValue;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, False);
      if Registry.ValueExists(ValueName) then
        Result := Registry.ReadFloat(ValueName);
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Read Errors
  end;
end;
{$ENDREGION}

{$REGION 'function DeleteRegistryKey(KeyName: String; const RootKey:HKey = HKEY_CURRENT_USER):Boolean;'}
function DeleteRegistryKey(KeyName: String; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.DeleteKey(KeyName);
      Result := True;
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Read Errors
  end;
end;
{$ENDREGION}

{$REGION 'function DeleteRegistryValue(KeyName: String; ValueName:string; const RootKey:HKey = HKEY_CURRENT_USER):Boolean;'}
function DeleteRegistryValue(KeyName: String; ValueName: string; const RootKey: HKey = HKEY_CURRENT_USER): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  try
    Registry := TRegistry.Create;
    try
      Registry.RootKey := RootKey;
      Registry.OpenKey(KeyName, False);
      Registry.DeleteValue(KeyName);
      Result := True;
    finally
      Registry.Free;
    end;
  except
    // Hide Registry Read Errors
  end;
end;
{$ENDREGION}

{$REGION 'procedure LoadRegistryKeys(KeyName: String; var KeyList:TStrings; const RootKey:HKey = HKEY_CURRENT_USER);'}
procedure LoadRegistryKeys(KeyName: String; KeyList: TStrings; const RootKey: HKey = HKEY_CURRENT_USER);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := RootKey;
    if Registry.OpenKey(KeyName, True) then
      Registry.GetKeyNames(KeyList);
  finally
    Registry.Free;
  end;
end;
{$ENDREGION}

end.
