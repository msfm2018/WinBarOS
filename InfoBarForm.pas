unit InfoBarForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.ShellAPI,  Vcl.ComCtrls, ActiveX,
  shlobj, comobj, System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TbottomForm = class(TForm)
    LVexeinfo: TListView;
    ImgList: TImageList;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure LVexeinfoDblClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
  private
    procedure WndProc(var Msg: TMessage); override;
    procedure DragFileInfo(Msg: TMessage);
    procedure AddExeInfo(Path, ExeName: string);
    function ShowIOO(Path, FileName: string): Boolean;
    function GetExeName(FileName: string): string;
    function ExeFromLink(lnkName: string): string;
    function ChangeFileName(FileName: string): string;
    procedure LoadIco;
    procedure CreateDefaultFile;
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}
uses
  core;

procedure TbottomForm.FormShow(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);

  CreateDefaultFile();
  LoadIco();
end;

procedure TbottomForm.WndProc(var Msg: TMessage);
begin
  inherited;
  if Msg.Msg = WM_DROPFILES then
  begin
    DragFileInfo(Msg);
  end;
end;

procedure TbottomForm.CreateDefaultFile;
var
  sysdir: pchar;
  SysTemDir: string;
begin
  Getmem(sysdir, 100);
  try
    getsystemdirectory(sysdir, 100);
    SysTemDir := string(sysdir);
  finally
    Freemem(sysdir, 100);
  end;

  if LVexeinfo.Items.Count = 0 then //���ļ�
  begin
    AddExeInfo(SysTemDir + '\notepad.exe', 'notepad');
    AddExeInfo(SysTemDir + '\calc.exe', 'calc');
    AddExeInfo(SysTemDir + '\mspaint.exe', 'mspaint');
    AddExeInfo(SysTemDir + '\cmd.exe', 'cmd');
    AddExeInfo(SysTemDir + '\mstsc.exe', 'mstsc');
  end;

end;

procedure TbottomForm.DragFileInfo(Msg: TMessage);
var
  i, number: integer;
  arrFileName: array[0..255] of Char;
  pFileName: PChar;
  strFileName: string;
begin
  pFileName := @arrFileName;
  number := DragQueryFile(Msg.wParam, $FFFFFFFF, nil, 0); //����ļ��ĸ���

  for i := 0 to number - 1 do
  begin
    DragQueryFile(Msg.wParam, i, pFileName, 255);
    strFileName := StrPas(arrFileName);
    if Pos('.lnk', strFileName) > 0 then
      AddExeInfo(ExeFromLink(strFileName), GetExeName(strFileName))
    else
      AddExeInfo(strFileName, GetExeName(strFileName));
  end;
  DragFinish(Msg.wParam);
end;

function TbottomForm.ExeFromLink(lnkName: string): string;
var
  aObj: IUnknown;
  MyPFile: IPersistFile;
  MyLink: IShellLink;
  WFileName: WideString;
  FileName: array[0..255] of char;
  pfd: WIN32_FIND_DATA;
begin
  aObj := CreateComObject(CLSID_ShellLink);
  MyPFile := aObj as IPersistFile;
  MyLink := aObj as IShellLink;

  WFileName := lnkName; //��һ��String����WideString��ת��������Delphi�Զ����
  MyPFile.Load(PWChar(WFileName), 0);

  MyLink.GetPath(FileName, 255, pfd, SLGP_UNCPRIORITY);

  Result := string(FileName);
end;

function TbottomForm.GetExeName(FileName: string): string;
begin
  result := ExtractFileName(FileName);
  exit;
end;

procedure TbottomForm.LVexeinfoDblClick(Sender: TObject);
var
  IP: Integer;
  FilePath: string;
  arr: array[0..MAX_PATH + 1] of Char;
  SysyTem: string;
begin
  if LVexeinfo.Selected = nil then
    Exit;

  GetSystemDirectory(arr, MAX_PATH);
  SysyTem := Copy(arr, 1, 3);

  FilePath := LVexeinfo.Selected.SubItems.Text;
  IP := Pos(#13#10, FilePath);
  FilePath := Copy(FilePath, 1, IP - 1);

  ShellExecute(0, nil, PChar(FilePath), nil, PChar(FilePath), SW_NORMAL);

end;

procedure TbottomForm.N1Click(Sender: TObject);
var
  IP: Integer;
  FilePath: string;
  i: Integer;
  Node: TListItem;
begin
  if LVexeinfo.Selected = Nil then
    Exit;

  Node := TListItem.Create(NIl);

  if LVexeinfo.SelCount > 0 then
    if MessageBox(handle, 'ȷ��', 'ɾ��', MB_ICONQUESTION + MB_YESNO) <> IDYes then
      Exit;

  for i := LVexeinfo.Items.Count - 1 downto 0 do
  begin
    if not LVexeinfo.Items[i].Selected then
      Continue;

    Node := LVexeinfo.Items[i];

    FilePath := LVexeinfo.Items[i].SubItems.Text;
    IP := Pos(#13#10, FilePath);
    FilePath := Copy(FilePath, 1, IP - 1);

    FilePath := ExtractFileName(FilePath);

    g_core.DatabaseManager.desktopdb.DeleteValue(FilePath);
    Node.Delete;
  end;

end;

procedure TbottomForm.AddExeInfo(Path, ExeName: string);
var
  FileName: string;
begin
  if Path = '' then
    Exit;

  if not (FileExists(Path) or DirectoryExists(Path)) then
  begin

    Exit;
  end;

  FileName := Path;                  //�����ļ���
  FileName := ExtractFileName(Path);
  var va := g_core.DatabaseManager.desktopdb.GetString(ExeName);
  if (va <> '') then
    exit;

  FileName := ChangeFileName(FileName);
  g_core.DatabaseManager.desktopdb.SetVarValue(FileName, Path);

  ShowIOO(Path, FileName); //��ʾͼ��
end;

procedure TbottomForm.LoadIco;
var
  i: Integer;
begin
  for i := 0 to LVexeinfo.Items.Count - 1 do
  begin
    LVexeinfo.Items.Delete(0);
  end;
  var keys := g_core.DatabaseManager.desktopdb.GetKeys;
  for var key in keys do

    ShowIOO(g_core.DatabaseManager.desktopdb.GetString(key), key); //��ʾͼ��


end;

function TbottomForm.ChangeFileName(FileName: string): string;
begin
  if UpperCase(FileName) = 'NOTEPAD.EXE' then
  begin

    Result := 'NOTEPAD';
    Exit;
  end;

  if UpperCase(FileName) = 'CALC.EXE' then
  begin
    Result := 'CALC';
    Exit;
  end;

  if UpperCase(FileName) = 'MSPAINT.EXE' then
  begin
    Result := 'MSPAINT';
    Exit;
  end;

  if UpperCase(FileName) = 'CMD.EXE' then
  begin
    Result := 'CMD';
    Exit;
  end;

  if UpperCase(FileName) = 'MSTSC.EXE' then
  begin
    Result := 'MSTSC';
    Exit;
  end;
  Result := FileName;
end;


function TbottomForm.ShowIOO(Path, FileName: string): Boolean;
var
  pIco: TIcon;
  bmpIco: TBitmap;
  IconIndex: word;
  item: TListItem;
  FilePath: string;
begin
  Result := True;
  FilePath := Path;

  if ((FileExists(Path) or DirectoryExists(Path))) and ((FileName) <> '') then
  begin
    IconIndex := 0;
    pIco := TIcon.Create;
    pIco.Handle := ExtractAssociatedIcon(Application.Handle, PChar(FilePath), IconIndex);
    if pIco.Handle > 0 then
    begin
      bmpIco := TBitmap.Create;
      bmpIco.PixelFormat := pf24bit;    //����ͼ��
      bmpIco.Height := pIco.Height;
      bmpIco.Width := pIco.Width;
      bmpIco.Canvas.Draw(0, 0, pIco);
      pIco.ReleaseHandle;

      item := LVexeinfo.Items.Add;
      item.Caption := (FileName);
      item.SubItems.Add(Path);
      item.ImageIndex := ImgList.Add(bmpIco, bmpIco);

    //  AddExeInfo(Path,FileName);
    end;
  end
  else
  begin
  //  DestTopDB.DeleteRecord(LoginID,EID,Path);
  end;
end;

end.

