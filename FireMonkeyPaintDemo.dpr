program FireMonkeyPaintDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  uPaintBox in 'uPaintBox.pas',
  uMain in 'uMain.pas' {MainForm},
  frmfilebrowseopen in 'frmfilebrowseopen.pas' {filebrowseopenfrm},
  frmSelectBmp in 'frmSelectBmp.pas' {SelectBmpfrm};

{$R *.res}

begin //TODO: add memory leak checking on exit
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSelectBmpfrm, SelectBmpfrm);
  Application.CreateForm(Tfilebrowseopenfrm, filebrowseopenfrm);
  Application.Run;
end.
