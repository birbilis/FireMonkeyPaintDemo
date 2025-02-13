unit uPaintBox;

interface

uses
  System.SysUtils,FMX.Surfaces,FMX.Colors,System.UITypes,System.Types, System.Classes,FMX.Controls,FMX.Graphics, FMX.Types, FMX.Objects;

type
  TFunctionDraw=(fdNone,fdPen,fdLine,fdRectangle,fdEllipse,fdFillBgr,fdBitmapStamp,fdPolyLine);
  TMyPaintBox = class(TPaintBox)
  private
    {$IFDEF POSIX}
    ffillBrush : TStrokeBrush;
    {$ENDIF}
    fDrawing:boolean;
    fbmpstamp:TBitmap;
    ffDraw:TFunctionDraw;
    fdrawbmp:TBitmap;
    fdrawbmprect:TRectF;
    fdrawrect:TRectF;//Paint box size
    pFrom,pTo:TPointF;
    fThickness:Single;
    ffgColor:TAlphaColor;
    fbgColor:TAlphaColor;
    fnofill:boolean;
    fcbrush:TBrush;//Current drawing Brush
    fcstroke:TStrokeBrush;//Current drawing stroke
    MouseMoved: Boolean;
    MouseDowned: Boolean;
    procedure SetForegroundColor(v:TAlphaColor);
    procedure SetBackgroundColor(v:TAlphaColor);
    procedure SetThickness(v:Single);
    procedure SetNoFill(v:boolean);
    procedure SetBitmapStamp(v:TBitmap);
  private
    procedure StartDrawing(startP:TPointF);
    procedure EndDrawing(startP:TPointF);
    procedure DoDraw(vCanvas: TCanvas;const drawall:boolean=true);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ForegroundColor:TAlphaColor read ffgColor write SetForegroundColor;
    property BackgroundColor:TAlphaColor read fbgColor write SetBackgroundColor;
    property Thickness:Single read fThickness write SetThickness;
    property FuncDraw:TFunctionDraw read ffDraw write ffDraw;
    property NoFill:Boolean read fnofill write SetNoFill;
    property BitmapStamp:TBitmap read fbmpstamp write SetBitmapStamp;
  public
    procedure MouseLeave;
    procedure FillColor(color:TAlphaColor);
    procedure SaveToJPEGStream(Stream: TStream);
    procedure SaveToBitmap(B: TBitmap); overload;
    procedure LoadFromBitmap(B: TBitmap);
    function GetBitmapWidth:Integer;
    function GetBitmapHeight:Integer;
    procedure SaveToBitmap(B: TBitmap; Width, Height: Integer); overload;
    procedure StampBitmap(X,Y: Single; B: TBitmap);
    {$IFDEF POSIX}
    procedure FFillerMod;
    {$ENDIF}
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MyPaintBox', [TMyPaintBox]);
end;

{ TMyPaintBox }

constructor TMyPaintBox.Create(AOwner: TComponent);
begin
  inherited;
  fbmpstamp := nil;
  Parent := TFmxObject(AOwner);
  Align :=  TAlignLayout.Client;
  ffDraw := TFunctionDraw.fdPen;
  fnofill := false;
  fDrawing := false;
  fThickness := 1;
  pFrom := PointF(-1, -1);
  pTo := PointF(-1, -1);

  fdrawrect := RectF(0,0,self.Width, self.Height);
  fdrawbmprect := RectF(0,0,self.Width, self.Height);
  fdrawbmp := TBitmap.Create(Round(fdrawbmprect.Width),Round(fdrawbmprect.Height));

  SetBackgroundColor(TAlphaColorRec.White);
  SetForegroundColor(TAlphaColorRec.Black);
  FillColor(fbgColor);

  {$IFDEF POSIX}
  FFillerMod;
  {$ENDIF}
end;

destructor TMyPaintBox.Destroy;
begin
  if (Assigned(fcbrush)) then
    fcbrush.Free;
  if (Assigned(fcstroke)) then
    fcstroke.Free;
  if (Assigned(fdrawbmp)) then
    fdrawbmp.Free;
  if Assigned(fbmpstamp) then
    fbmpstamp.Free;

  {$IFDEF POSIX}
  if Assigned(ffillBrush) then
    FreeAndNil(ffillBrush);
  {$ENDIF}

  inherited;
end;

procedure TMyPaintBox.DoDraw(vCanvas: TCanvas; const drawall: boolean);
var
  r,rd:TRectF;
begin
  if (drawall) then
    self.Canvas.DrawBitmap(fdrawbmp,fdrawrect,fdrawrect,1);

  if (ffdraw=TFunctionDraw.fdNone) or (not fdrawing) then exit;

  r := TRectF.Create(pFrom, pTo);

  with vCanvas do
    if BeginScene then
      try

        case ffdraw of
          {$IFDEF MSWINDOWS}
          TFunctionDraw.fdPen:
            DrawLine(pFrom,pTo,1,fcstroke);
          {$ENDIF}

          TFunctionDraw.fdLine:
            DrawLine(pFrom,pTo,1,fcstroke);

          TFunctionDraw.fdRectangle:
          begin
              if not fnofill then
                FillRect(r,0,0,[TCorner.TopLeft],1,fcbrush);
              DrawRect(r,0,0,[TCorner.TopLeft],1,fcstroke);
          end;

          TFunctionDraw.fdEllipse:
          begin
            if not fnofill then
              FillEllipse(r,1,fcbrush);

            {$IFDEF VER310}
            DrawEllipse(r,1,fcstroke);
            {$ENDIF}
          end;

          TFunctionDraw.fdFillBgr:
            Clear(fbgColor);

          TFunctionDraw.fdBitmapStamp:
            if (Assigned(fbmpstamp)) then
            begin
              r := TRectF.Create(PointF(0,0),fbmpstamp.Width,fbmpstamp.Height);
              rd := TRectF.Create(PointF(pTo.X,pTo.Y),fbmpstamp.Width,fbmpstamp.Height);
              DrawBitmap(fbmpstamp,r,rd,1);
            end;

        end;

      finally
        EndScene;
      end;

end;

procedure TMyPaintBox.StampBitmap(X, Y: Single; B: TBitmap);
var
  r, rd:TRectF;
begin
  with fdrawbmp.Canvas do
    if BeginScene then
      try

        if Assigned(B) then
        begin
          r := TRectF.Create(PointF(0,0),B.Width,B.Height);
          rd := TRectF.Create(PointF(X,Y),B.Width,B.Height);
          DrawBitmap(B,r,rd,1);
        end;

      finally
        EndScene;
      end;

  {$IFDEF POSIX}
  InvalidateRect(fdrawrect);
  {$ENDIF}
end;

procedure TMyPaintBox.EndDrawing(startP: TPointF);
begin
  if (not fdrawing) then exit;

  pTo := PointF(startP.X,startP.Y);
  DoDraw(fdrawbmp.Canvas, false);

  fdrawing := false;
  pFrom := PointF(-1, -1);
  pTo := PointF(-1, -1);
end;

procedure TMyPaintBox.FillColor(color: TAlphaColor);
begin
  with fdrawbmp.Canvas do
  begin
    BeginScene();
    Clear(color);
    EndScene;
  end;
end;

procedure TMyPaintBox.MouseLeave;
begin
  if (not MouseDowned) then
    if (not fdrawing) then
    begin
      //StartDrawing(PointF(X, Y));
    end;

  if (not MouseMoved) then
  begin
    {$IFDEF MSWINDOWS}
    //pTo := PointF(X, Y);
    InvalidateRect(fdrawrect);
    case ffdraw of
      TFunctionDraw.fdPen: //if (pFrom<>pTo) then
      begin
      DoDraw(fdrawbmp.Canvas,false);
        pFrom := pTo;
      end;
    end;
    {$ENDIF}
  end;

  MouseMoved := False;
  MouseDowned := False;
  fdrawing := False;

  //EndDrawing(PointF(X, Y));
  {$IFDEF POSIX}
  InvalidateRect(fdrawrect);
  {$ENDIF}
end;

procedure TMyPaintBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;

  if (not fdrawing) then
    StartDrawing(PointF(X, Y));

  MouseDowned := True;
end;

procedure TMyPaintBox.MouseMove(Shift: TShiftState; X, Y: Single);
{$IFDEF POSIX}
var
  Radius       : Single;
  xDir, yDir   : Single;
  Dx, Dy       : Single;
  Ratio        : Single;
  MoveX, MoveY : Single;
{$ENDIF}
begin
  inherited;

  if (not fdrawing) then exit;

  {$IFDEF POSIX}
  Radius := fThickness / 2;
  {$ENDIF}

  pTo := PointF(X, Y);

  InvalidateRect(fdrawrect);

  case ffdraw of
    TFunctionDraw.fdPen:
    begin
      {$IFDEF POSIX}
      if ( pFrom.Round <> pTo.Round ) then
        begin
         { Direction detection from pFrom to pTo }
         { to adjust start center                }

         if pTo.Y >= pFrom.Y then yDir := -1 else yDir := 1;
         if pTo.X >= pFrom.X then xDir := -1 else xDir := 1;

         { Quantify movement }

         Dx := ABS ( pTo.X - pFrom.X );
         Dy := ABS ( pTo.Y - pFrom.Y );

         if ABS ( Dy ) > ABS ( Dx ) then
           begin
              Ratio   := ABS ( Radius / Dy * Dx );
              MoveY   := Radius  * yDir;
              pFrom.Y := pFrom.Y + MoveY;
              MoveX   := Ratio   * xDir;
              pFrom.X := pFrom.X + MoveX;
           end
         else
           begin
              Ratio   := ABS ( Radius / Dx * Dy );
              MoveX   := Radius  * xDir;
              pFrom.X := pFrom.X + MoveX;
              MoveY   := Ratio   * yDir;
              pFrom.Y := pFrom.Y + MoveY;
           end;

         fdrawbmp.Canvas.BeginScene ();
            fdrawbmp.Canvas.DrawLine ( pFrom, pTo, 1, ffillBrush );
         fdrawbmp.Canvas.EndScene;

         { Direction detection end of line }
         { to adjust end of line center    }

         IF pTo.Y >= pFrom.Y THEN yDir := -1 ELSE yDir := 1;
         IF pTo.X >= pFrom.X THEN xDir := -1 ELSE xDir := 1;

         { Quantify movement }

         Dx := ABS ( pTo.X - pFrom.X );
         Dy := ABS ( pTo.Y - pFrom.Y );

         if ABS ( Dy ) > ABS ( Dx ) then
           begin
                Ratio   := ABS ( Radius / Dy * Dx );
                MoveY   := Radius * yDir;
                pFrom.Y := pTo.Y  + MoveY;
                MoveX   := Ratio  * xDir;
                pFrom.X := pTo.X  + MoveX;
           end
         else
           begin
                Ratio   := ABS ( Radius / Dx * Dy );
                MoveX   := Radius * xDir;
                pFrom.X := pTo.X  + MoveX;
                MoveY   := Ratio  * yDir;
                pFrom.Y := pTo.Y  + MoveY;
           end;
        end;
        {$ENDIF}

        {$IFDEF MSWINDOWS}
	      DoDraw(fdrawbmp.Canvas,false);
	      pFrom := pTo;
        {$ENDIF}
    end;

    TFunctionDraw.fdBitmapStamp: //if (pFrom<>pTo) then
    begin
      DoDraw(fdrawbmp.Canvas,false);
      pFrom := pTo;
    end;
  end;

  MouseMoved := True;
end;

procedure TMyPaintBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  inherited;
  if (MouseDowned = False) then
  begin
    if (not fdrawing) then
    begin
      StartDrawing(PointF(X, Y));
    end;
  end;

  if (MouseMoved = False) then
  begin
    {$IFDEF MSWINDOWS}
    pTo := PointF(X, Y);
    InvalidateRect(fdrawrect);
    case ffdraw of
      TFunctionDraw.fdPen: //if (pFrom<>pTo) then
      begin
        DoDraw(fdrawbmp.Canvas,false);
        pFrom := pTo;
      end;
    end;
    {$ENDIF}
  end;

  MouseMoved := False;
  MouseDowned := False;

  EndDrawing(PointF(X, Y));
  {$IFDEF POSIX}
  InvalidateRect(fdrawrect);
  {$ENDIF}
end;

procedure TMyPaintBox.Paint;
begin
  inherited;

  if (csDesigning in ComponentState) then exit;

  DoDraw(self.Canvas);
end;

procedure TMyPaintBox.SaveToJPEGStream(Stream: TStream);
var
  Surf: TBitmapSurface;
  saveParams : TBitmapCodecSaveParams;
begin
  Surf := TBitmapSurface.Create;
  try
    Surf.Assign(fdrawbmp);
    saveparams.Quality := 93; // <-- always stops here with an AV error
    TBitmapCodecManager.SaveToStream(Stream, Surf, '.jpg',@saveParams);
  finally
    Surf.Free;
  end;
end;

procedure TMyPaintBox.SaveToBitmap(B: TBitmap);
begin
  try
    B.Assign(fdrawbmp);
  finally
  end;
end;

procedure TMyPaintBox.SaveToBitmap(B: TBitmap; Width, Height: Integer);
begin
	if B.Width = 0 then
	Exit;
	if fdrawbmp <> nil then
	begin
		//fdrawbmp.DrawBitmap(B, RectF(0, 0, fdrawbmp.Width, fdrawbmp.Height), RectF(0,0, Width, Height), 1, False);
    B.Assign(fdrawbmp.CreateThumbnail(Width,Height));
	end;
end;

procedure TMyPaintBox.LoadFromBitmap(B: TBitmap);
var
  r,rd: TRectF;
begin
  try
    if Assigned(fdrawbmp) then
     begin
        r := TRectF.Create(PointF(0,0),B.Width,B.Height);
        rd := TRectF.Create(PointF(0,0),B.Width,B.Height);
        fdrawbmp.Canvas.BeginScene();
        fdrawbmp.Canvas.DrawBitmap(B,r,rd,1);
        fdrawbmp.Canvas.EndScene;
        InvalidateRect(fdrawrect);
     end;
  finally
    //TODO: ???
  end;
end;

function TMyPaintBox.GetBitmapWidth: Integer;
begin
  Result := fdrawbmp.Width;
end;

function TMyPaintBox.GetBitmapHeight: Integer;
begin
  Result := fdrawbmp.Height;
end;

procedure TMyPaintBox.SetBackgroundColor(v: TAlphaColor);
begin
  if (v=fbgColor) then exit;

  if (Assigned(fcbrush)) then
    fcbrush.Free;

  fbgColor := v;
  fcbrush := TBrush.Create(TBrushKind.Solid,fbgColor);
end;

procedure TMyPaintBox.SetBitmapStamp(v: TBitmap);
begin
  if not Assigned(v) then exit;

  if Assigned(fbmpstamp) then
    fbmpstamp.Free;

  fbmpstamp := TBitmap.Create(0,0);
  fbmpstamp.Assign(v);
end;

procedure TMyPaintBox.SetForegroundColor(v: TAlphaColor);
begin
  if (v=ffgColor) then exit;

  if (Assigned(fcstroke)) then
    fcstroke.Free;

  ffgColor := v;

  fcstroke := TStrokeBrush.Create(TBrushKind.Solid,ffgColor);
  fcstroke.DefaultColor := ffgColor;
  fcstroke.Thickness := fThickness;

  {$IFDEF POSIX}
  ffillermod;
  {$ENDIF}
end;

procedure TMyPaintBox.SetNoFill(v: boolean);
begin
  if fnofill<>v then
    fnofill := v;
end;

procedure TMyPaintBox.SetThickness(v: Single);
begin
  if (v=fThickness) then exit;

  if (Assigned(fcstroke)) then
    fcstroke.Free;

  fThickness := v;

  fcstroke := TStrokeBrush.Create(TBrushKind.Solid, ffgColor);
  fcstroke.DefaultColor := ffgColor;
  fcstroke.Thickness := fThickness;
  fcstroke.Cap := TStrokeCap.Round;

  {$IFDEF POSIX}
  ffillermod;
  {$ENDIF}
end;

procedure TMyPaintBox.StartDrawing(startP: TPointF);
begin
  if (csDesigning in ComponentState) then exit;
  if (fDrawing) or (ffDraw=TFunctionDraw.fdNone) then exit;

  pFrom := PointF(startP.X, startP.Y);
  pTo := PointF(startP.X, startP.Y);
  fDrawing := true;
end;

{$IFDEF POSIX}
procedure TMyPaintBox.FFillerMod;
Begin
  if not Assigned(ffillBrush) then
   ffillBrush := TStrokeBrush.Create(TBrushKind.bkSolid, ffgcolor);

  ffillBrush.Thickness := fThickness;
  ffillBrush.Cap       := TStrokeCap.scRound;
  ffillBrush.Join      := TStrokeJoin.sjRound;
  ffillBrush.Color     := ffgcolor;
End;
{$ENDIF}

end.
