unit UFigures;

{$mode objfpc}{$H+}

interface

uses
	Classes, SysUtils, Controls, FileUtil, Forms, Graphics, Dialogs, Menus,
  ExtCtrls, Math, UDoublePoint, UPaintSpace, FPCanvas, UUtils, UFigureParams,
  UGeometry;

type

  TTwoDoublePointsArray = array[0..1] of TDoublePoint;

  TFigure = class
  strict protected
    FBounds: TTwoDoublePointsArray;
    FPoints: TDoublePointArray;
    FSelected: Boolean;
    class procedure SetSelectionEllipseParams(APen: TPen; ABrush: TBrush);
    procedure DrawSelection(APaintSpace: TPaintSpace); virtual; abstract;
    procedure SetSelectionParams(APen: TPen; ABrush: TBrush); virtual; abstract;
  public
    property Points: TDoublePointArray read FPoints write FPoints;
    property Bounds: TTwoDoublePointsArray read FBounds;
    property Selected: Boolean read FSelected write FSelected;
    function IsPointInclude(APoint: TDoublePoint): Boolean; virtual; abstract;
    function IsFullInRect(A, B: TDoublePoint): Boolean; virtual; abstract;
    function IsPartInRect(A, B: TDoublePoint): Boolean; virtual; abstract;
    function IsValid: Boolean; virtual; abstract;
    procedure Move(AValue: TDoublePoint);
    procedure SetPointsLength(ALength: Integer);
    procedure IncreasePointsLength;
    procedure Bake; virtual;
    procedure Draw(APaintSpace: TPaintSpace); virtual; abstract;
  end;

  TFigureArray = array of TFigure;

  TLineFigure = class(TFigure)
  strict protected
    FPenParams: TPenParams;
    procedure DrawSelection(APaintSpace: TPaintSpace); override;
    procedure SetSelectionParams(APen: TPen; ABrush: TBrush); override;
  public
    property PenParams: TPenParams read FPenParams write FPenParams;
    constructor Create;
    function IsPointInclude(APoint: TDoublePoint): Boolean; override;
    function IsFullInRect(A, B: TDoublePoint): Boolean; override;
    function IsPartInRect(A, B: TDoublePoint): Boolean; override;
    function IsValid: Boolean; override;
    procedure Draw(APaintSpace: TPaintSpace); override;
  end;

  TShapeFigure = class(TLineFigure)
  strict protected
    FBrushParams: TBrushParams;
    procedure SetSelectionParams(APen: TPen; ABrush: TBrush); override;
  public
    constructor Create;
    property BrushParams: TBrushParams read FBrushParams write FBrushParams;
    function IsValid: Boolean; override;
  end;

  TRectFigure = class(TShapeFigure)
  public
    constructor Create;
    function IsPointInclude(APoint: TDoublePoint): Boolean; override;
    procedure Draw(APaintSpace: TPaintSpace); override;
  end;

  TPolygonFigure = class(TShapeFigure)
  strict protected
    procedure DrawSelection(APaintSpace: TPaintSpace); override;
  public
    constructor Create;
    function IsValid: Boolean; override;
    function IsPointInclude(APoint: TDoublePoint): Boolean; override;
    procedure Draw(APaintSpace: TPaintSpace); override;
  end;

  TRectSplitOffFigure = class(TRectFigure)
  public
    constructor Create;
    function IsPointInclude(APoint: TDoublePoint): Boolean; override;
    procedure Draw(APaintSpace: TPaintSpace); override;
  end;

  TEllipseFigure = class(TShapeFigure)
  strict protected
    procedure DrawSelection(APaintSpace: TPaintSpace); override;
	public
    constructor Create;
    function IsPointInclude(APoint: TDoublePoint): Boolean; override;
    procedure Draw(APaintSpace: TPaintSpace); override;
  end;

  TRoundedRectFigure = class(TShapeFigure)
  private
    FRounding: Integer;
	public
    property Rounding: Integer read FRounding write FRounding;
    constructor Create;
    function IsPointInclude(APoint: TDoublePoint): Boolean; override;
    procedure Draw(APaintSpace: TPaintSpace); override;
  end;

  TFigures = class
 	strict private
    FContent: TFigureArray;
    FIsSelected: array of Boolean;
    FFigureAddEvent: TEventHandler;
    FBounds: TDoubleRect;
    procedure SetBounds;
  public
    property OnFigureAdd: TEventHandler read FFigureAddEvent write FFigureAddEvent;
    constructor Create;
    function SelectFigure(APoint: TDoublePoint): TFigure;
    function GetFigure(APoint: TDoublePoint): TFigure;
    function ReverseSelectFigure(APoint: TDoublePoint): TFigure;
    procedure SpaceSelectFullFigures(A, B: TDoublePoint);
    procedure SpaceSelectPartFigures(A, B: TDoublePoint);
    procedure SelectAllFigures;
    procedure UnSelectAllFigures;
    function CanSelectFigure(APoint: TDoublePoint): Boolean;
    procedure MoveSelected(AValue: TDoublePoint);
    procedure AddFigure(AFigure: TFigure);
    function RemoveFigure(AElementID: Longint): Boolean;
    function RemoveLastFigure: Boolean;
    procedure BakeLastFigure;
    procedure GetBounds(var AMin: TDoublePoint; var AMax: TDoublePoint);
  	procedure Draw(APaintSpace: TPaintSpace);
    destructor Destroy; override;
  end;

  procedure SetBounds(var ABounds: TTwoDoublePointsArray; APoint: TDoublePoint);

implementation

procedure SetBounds(var ABounds: TTwoDoublePointsArray; APoint: TDoublePoint);
begin
  if APoint.X < ABounds[0].X then
    ABounds[0].X:= APoint.X;
  if APoint.Y < ABounds[0].Y then
    ABounds[0].Y:= APoint.Y;
  if APoint.X > ABounds[1].X then
    ABounds[1].X:= APoint.X;
  if APoint.Y > ABounds[1].Y then
    ABounds[1].Y:= APoint.Y;
end;

class procedure TFigure.SetSelectionEllipseParams(APen: TPen; ABrush: TBrush);
begin
  APen.Color:= RGBToColor(100, 100, 100);
  APen.Width:= 1;
  APen.Style:= psSolid;
  ABrush.Style:= bsClear;
  ABrush.Color:= clWhite;
end;

procedure TFigure.IncreasePointsLength;
begin
  SetLength(FPoints, Length(FPoints)+1);
end;

procedure TFigure.Move(AValue: TDoublePoint);
var
  i: Integer;
begin
  for i:= 0 to High(FPoints) do
    FPoints[i]+= AValue;
  FBounds[0]+= AValue;
  FBounds[1]+= AValue;
end;

procedure TFigure.SetPointsLength(ALength: Integer);
begin
  SetLength(FPoints, ALength);
end;

procedure TFigure.Bake;
var
  P: TDoublePoint;
begin
  FBounds[0]:= FPoints[0];
  FBounds[1]:= FPoints[0];
  for P in FPoints do
    SetBounds(FBounds, P);
end;

procedure TLineFigure.DrawSelection(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetSelectionEllipseParams(Canvas.Pen, Canvas.Brush);
    Canvas.EllipseC(ToLocal(FPoints[0]).X, ToLocal(FPoints[0]).Y, 3, 3);
    Canvas.EllipseC(ToLocal(FPoints[High(FPoints)]).X, ToLocal(FPoints[High(FPoints)]).Y, 3, 3);
  end;
end;

procedure TLineFigure.SetSelectionParams(APen: TPen; ABrush: TBrush);
begin
  APen.Width:= APen.Width+1;
end;

constructor TLineFigure.Create;
begin
  SetLength(FPoints, 2);
end;

function TLineFigure.IsPointInclude(APoint: TDoublePoint): Boolean;
var
  i: Integer;
  A, B: TDoublePoint;
begin
  for i:= 0 to High(FPoints)-1 do begin
    A:= FPoints[i]; B:= FPoints[i+1];
    if IsPointInLineSegment(A, B, APoint, 1600) then Exit(true);
  end;
  Exit(False);
end;

function TLineFigure.IsFullInRect(A, B: TDoublePoint): Boolean;
var
  p: TDoublePoint;
begin
  for p in FPoints do
    if not ((Min(A.X, B.X) <= p.X) and (p.X <= Max(A.X, B.X)) and
      (Min(A.Y, B.Y) <= p.Y) and (p.Y <= Max(A.Y, B.Y))) then
      Exit(false);
  Exit(true);
end;

function TLineFigure.IsPartInRect(A, B: TDoublePoint): Boolean; // FIX!
var
  p: TDoublePoint;
begin
  for p in FPoints do
    if (Min(A.X, B.X) <= p.X) and (p.X <= Max(A.X, B.X)) and
      (Min(A.Y, B.Y) <= p.Y) and (p.Y <= Max(A.Y, B.Y)) then
      Exit(true);
  Exit(false);
end;

function TLineFigure.IsValid: Boolean;
begin
  Result:= (Length(FPoints)>=2);
end;

procedure TLineFigure.Draw(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetParams(FPenParams, Canvas.Pen);
    if FSelected then
      SetSelectionParams(Canvas.Pen, Canvas.Brush);
    Canvas.Polyline(ToLocal(FPoints));
    if FSelected then
      DrawSelection(APaintSpace);
  end;
end;

procedure TShapeFigure.SetSelectionParams(APen: TPen; ABrush: TBrush);
begin
  APen.Width:= APen.Width+1;
  ABrush.Color:= ColorToRGB(ABrush.Color)-$101010;
end;

constructor TShapeFigure.Create;
begin
  inherited Create;
end;

function TShapeFigure.IsValid: Boolean;
begin
  Result:= (FPoints[0].X <> FPoints[1].X) and (FPoints[0].Y <> FPoints[1].Y);
end;

constructor TRectFigure.Create;
begin
  inherited Create;
end;

function TRectFigure.IsPointInclude(APoint: TDoublePoint): Boolean;
begin
  if (FBounds[0].X<=APoint.X) and (APoint.X<=FBounds[1].X) and
    (FBounds[0].Y<=APoint.Y) and (APoint.Y<=FBounds[1].Y) then
    Exit(true);
  Exit(false);
end;

procedure TRectFigure.Draw(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetParams(FPenParams, Canvas.Pen);
    SetParams(FBrushParams, Canvas.Brush);
    if FSelected then
      SetSelectionParams(Canvas.Pen, Canvas.Brush);
    Canvas.Rectangle(ToLocal(FPoints[0]).X, ToLocal(FPoints[0]).Y,
                     ToLocal(FPoints[1]).X, ToLocal(FPoints[1]).Y);
    if FSelected then
      DrawSelection(APaintSpace);
  end;
end;

procedure TPolygonFigure.DrawSelection(APaintSpace: TPaintSpace);
var
  p: TDoublePoint;
begin
  with APaintSpace do begin
    SetSelectionEllipseParams(Canvas.Pen, Canvas.Brush);
    for p in FPoints do
      Canvas.EllipseC(ToLocal(p).X, ToLocal(p).Y, 3, 3);
  end;
end;

constructor TPolygonFigure.Create;
begin
end;

function TPolygonFigure.IsValid: Boolean;
begin
  Result:= FPoints[0] <> FPoints[1];
end;

function TPolygonFigure.IsPointInclude(APoint: TDoublePoint): Boolean;
var
  i: Integer;
begin
  for i:= 0 to High(FPoints)-1 do
    if GetVecMultiplyLength(FPoints[i+1]-FPoints[i], APoint-FPoints[i]) < 0 then
      Exit(false);
  if GetVecMultiplyLength(FPoints[0]-FPoints[High(FPoints)], APoint-FPoints[High(FPoints)]) < 0 then
    Exit(false);
  Result:= true;
end;

procedure TPolygonFigure.Draw(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetParams(FPenParams, Canvas.Pen);
    SetParams(FBrushParams, Canvas.Brush);
    if FSelected then
      SetSelectionParams(Canvas.Pen, Canvas.Brush);
    Canvas.Polygon(ToLocal(Points));
    if FSelected then
      DrawSelection(APaintSpace);
  end;
end;

constructor TRectSplitOffFigure.Create;
begin
  inherited Create;
  FPenParams.Style:= psDash;
end;

function TRectSplitOffFigure.IsPointInclude(APoint: TDoublePoint): Boolean;
begin

end;

procedure TRectSplitOffFigure.Draw(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetParams(FPenParams, Canvas.Pen);
    Canvas.Frame(ToLocal(FPoints[0]).X, ToLocal(FPoints[0]).Y,
                 ToLocal(FPoints[1]).X, ToLocal(FPoints[1]).Y);
  end;
end;

procedure TEllipseFigure.DrawSelection(APaintSpace: TPaintSpace);
var
  middle: TDoublePoint;
begin
  with APaintSpace do begin
    middle:= GetDoublePoint(0.5*FBounds[0].X+0.5*FBounds[1].X,
                            0.5*FBounds[0].Y+0.5*FBounds[1].Y);
    SetSelectionEllipseParams(Canvas.Pen, Canvas.Brush);
    Canvas.EllipseC(ToLocal(middle).X, ToLocal(middle).Y, 3, 3);
    Canvas.EllipseC(ToLocal(middle).X, ToLocal(FBounds[0]).Y, 3, 3);
    Canvas.EllipseC(ToLocal(middle).X, ToLocal(FBounds[1]).Y, 3, 3);
    Canvas.EllipseC(ToLocal(FBounds[0]).X, ToLocal(middle).Y, 3, 3);
    Canvas.EllipseC(ToLocal(FBounds[1]).X, ToLocal(middle).Y, 3, 3);
  end;
end;

constructor TEllipseFigure.Create;
begin
  inherited Create;
end;

function TEllipseFigure.IsPointInclude(APoint: TDoublePoint): Boolean;
var
  F1, F2, L, R, O: TDoublePoint;
  c: Double;
begin
  L:= GetDoublePoint(Min(FPoints[0].X, FPoints[1].X), Min(FPoints[0].Y, FPoints[1].Y));
  R:= GetDoublePoint(Max(FPoints[0].X, FPoints[1].X), Max(FPoints[0].Y, FPoints[1].Y));
  O:= L+(R-L)/2;
  APoint:= APoint-O; L:= L-O; R:= R-O;
  if R.X-L.X > R.Y-L.Y then begin
    c:= sqrt(sqr(R.X)-sqr(L.Y));
    F1:= GetDoublePoint(-c ,0); F2:= GetDoublePoint(c, 0);
    if (APoint-F1).Length+(APoint-F2).Length <= 2*R.X then Exit(true);
  end else begin
    c:= sqrt(sqr(L.Y)-sqr(R.X));
    F1:= GetDoublePoint(0, c); F2:= GetDoublePoint(0, -c);
    if (APoint-F1).Length+(APoint-F2).Length <= -2*L.Y then Exit(true);
  end;
  Exit(false);
end;

procedure TEllipseFigure.Draw(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetParams(FPenParams, Canvas.Pen);
    SetParams(FBrushParams, Canvas.Brush);
    if FSelected then
      SetSelectionParams(Canvas.Pen, Canvas.Brush);
    Canvas.Ellipse(ToLocal(FPoints[0]).X, ToLocal(FPoints[0]).Y,
                   ToLocal(FPoints[1]).X, ToLocal(FPoints[1]).Y);
    if FSelected then
      DrawSelection(APaintSpace);
  end;
end;

constructor TRoundedRectFigure.Create;
begin
  inherited Create;
end;

function TRoundedRectFigure.IsPointInclude(APoint: TDoublePoint): Boolean;
begin
  if (FBounds[0].X<=APoint.X) and (APoint.X<=FBounds[1].X) and
    (FBounds[0].Y<=APoint.Y) and (APoint.Y<=FBounds[1].Y) then
    Exit(true);
  Exit(false);
end;

procedure TRoundedRectFigure.Draw(APaintSpace: TPaintSpace);
begin
  with APaintSpace do begin
    SetParams(FPenParams, Canvas.Pen);
    SetParams(FBrushParams, Canvas.Brush);
    if FSelected then
      SetSelectionParams(Canvas.Pen, Canvas.Brush);
    Canvas.RoundRect(ToLocal(FPoints[0]).X, ToLocal(FPoints[0]).Y,
                     ToLocal(FPoints[1]).X, ToLocal(FPoints[1]).Y,
                     FRounding, FRounding);
    if FSelected then
      DrawSelection(APaintSpace);
  end;
end;

constructor TFigures.Create;
begin
	FContent:= nil
end;

function TFigures.SelectFigure(APoint: TDoublePoint): TFigure;
var
    i: Integer;
begin
  for i:= High(FContent) downto 0 do
    if FContent[i].IsPointInclude(APoint) then begin
      FIsSelected[i]:= true;
      Exit(FContent[i]);
    end;
  Result:= nil;
end;

function TFigures.GetFigure(APoint: TDoublePoint): TFigure;
var
  i: Integer;
begin
for i:= High(FContent) downto 0 do
    if FContent[i].IsPointInclude(APoint) then begin
      Exit(FContent[i]);
    end;
  Result:= nil;
end;

function TFigures.ReverseSelectFigure(APoint: TDoublePoint): TFigure;
var
    i: Integer;
begin
  for i:= High(FContent) downto 0 do
    if FContent[i].IsPointInclude(APoint) then begin
      FIsSelected[i]:= not FIsSelected[i];
      Exit(FContent[i]);
    end;
  Result:= nil;
end;

procedure TFigures.SpaceSelectFullFigures(A, B: TDoublePoint);
var
  i: Integer;
begin
  write('Triggered');
  for i:= High(FContent) downto 0 do
    if FContent[i].IsFullInRect(A, B) then
      FIsSelected[i]:= true;
end;

procedure TFigures.SpaceSelectPartFigures(A, B: TDoublePoint);
var
  i: Integer;
begin
  for i:= High(FContent) downto 0 do
    if FContent[i].IsPartInRect(A, B) then
      FIsSelected[i]:= true;
end;

procedure TFigures.SelectAllFigures;
var
  i: Integer;
begin
  for i:= 0 to High(FIsSelected) do
    FIsSelected[i]:= true;
end;

procedure TFigures.UnSelectAllFigures;
var
  i: Integer;
begin
  for i:= 0 to High(FIsSelected) do
    FIsSelected[i]:= false;
end;

function TFigures.CanSelectFigure(APoint: TDoublePoint): Boolean;
var
    i: Integer;
begin
  for i:= High(FContent) downto 0 do
    if FContent[i].IsPointInclude(APoint) then
      Exit(true);
  Result:= false;
end;

procedure TFigures.MoveSelected(AValue: TDoublePoint);
var
  f: TFigure;
begin
  for f in FContent do
    if f.Selected then f.Move(AValue);
end;

procedure TFigures.AddFigure(AFigure: TFigure);
begin
  SetLength(FContent, Length(FContent)+1);
  FContent[High(FContent)]:= AFigure;
  SetLength(FIsSelected, Length(FIsSelected)+1);
  FIsSelected[High(FIsSelected)]:= false;
end;

procedure TFigures.SetBounds;
var
  Figure: TFigure;
  Min, Max: TDoublePoint;
begin
  if FContent = nil then exit;
  Min:= FContent[0].Bounds[0];
  Max:= FContent[0].Bounds[1];
  for Figure in FContent do begin
    if Min.X > Figure.Bounds[0].X then
      Min.X:= Figure.Bounds[0].X;
    if Min.Y > Figure.Bounds[0].Y then
      Min.Y:= Figure.Bounds[0].Y;
    if Max.X < Figure.Bounds[1].X then
      Max.X:= Figure.Bounds[1].X;
    if Max.Y < Figure.Bounds[1].Y then
      Max.Y:= Figure.Bounds[1].Y;
  end;
  Min.X:= Min.X-5; Min.Y:= Min.Y-5;
  Max.X:= Max.X+5; Max.Y:= Max.Y+5;
  FBounds.TopLeft:= Min;
  FBounds.Width:= Max.X-FBounds.TopLeft.X;
  FBounds.Height:= Max.Y-FBounds.TopLeft.Y;
end;

function TFigures.RemoveLastFigure: Boolean;
begin
  if(Length(FContent) = 0) then Exit(false);
  FContent[High(FContent)].Free;
  SetLength(FContent, Length(FContent)-1);
  SetLength(FIsSelected, Length(FIsSelected)-1);
end;

procedure TFigures.BakeLastFigure;
begin
  FContent[High(FContent)].Bake;
  SetBounds;
  if Assigned(FFigureAddEvent) then
    FFigureAddEvent;
end;

procedure TFigures.GetBounds(var AMin: TDoublePoint; var AMax: TDoublePoint);
begin
  AMin:= FBounds.TopLeft;
  AMax.X:= FBounds.Width+FBounds.TopLeft.X;
  AMax.Y:= FBounds.Height+FBounds.TopLeft.Y;
end;

function TFigures.RemoveFigure(AElementID: Longint): Boolean;
var
  i: Longint;
begin
  if(AElementID < Low(FContent)) or (AElementID >= High(FContent)) then Exit(false);
	FContent[AElementID].Free;
  for i:= AElementID to High(FContent)-1 do begin
    FContent[AElementID]:= FContent[AElementID+1];
  end;
	SetLength(FContent, Length(FContent)-1);
  SetLength(FIsSelected, Length(FIsSelected)+1);
  Exit(true);
end;

procedure TFigures.Draw(APaintSpace: TPaintSpace);
var
  i: Integer;
begin
  for i:= 0 to High(FContent) do begin
    FContent[i].Selected:= FIsSelected[i];
    FContent[i].Draw(APaintSpace);
  end;
end;

destructor TFigures.Destroy;
var
  Figure: TFigure;
begin
  for Figure in FContent do
    Figure.Free;
end;

end.

