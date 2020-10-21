unit gnuplot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Process, multiarray;

type
  TLegendPosition = (lpLeftTop, lpLeftBottom, lpRightTop, lpRightBottom, lpOutside);

  TFigure = class
  private
    PlotCount: integer;
    FigureScript: TStringList;
    PlotScript: TStringList;
  public
    FigureTitle: string;
    LegendPosition: TLegendPosition;
    XLabel: string;
    YLabel: string;
    constructor Create(aFigureTitle, aXLabel, aYLabel: string);
    destructor Destroy; override;
    procedure AddPlot(X: TMultiArray; PlotType, PlotLabel: string);
    procedure AddLinePlot(X: TMultiArray; PlotLabel: string);
    procedure AddScatterPlot(X: TMultiArray; PlotLabel: string; PlotType: integer = 7);
    procedure Show;
  end;

implementation

{ TFigure }

constructor TFigure.Create(aFigureTitle, aXLabel, aYLabel: string);
begin
  PlotCount := 0;
  FigureScript := TStringList.Create;
  PlotScript := TStringList.Create;
  FigureTitle := aFigureTitle;
  XLabel := aXLabel;
  YLabel := aYLabel;

  LegendPosition := lpRightTop;
end;

destructor TFigure.Destroy;
begin
  FigureScript.Free;
  PlotScript.Free;
  inherited Destroy;
end;

procedure TFigure.AddPlot(X: TMultiArray; PlotType, PlotLabel: string);
var
  fn: string;
begin
  Inc(PlotCount);
  fn := Format('__MAT_TMP_%d__', [PlotCount]);
  MatToStringList(X, ' ').SaveToFile(fn);
  PlotScript.Add(Format('''%s'' with %s title ''%s'',', [fn, PlotType, PlotLabel]));
end;

procedure TFigure.AddLinePlot(X: TMultiArray; PlotLabel: string);
begin
  AddPlot(X, 'line', PlotLabel);
end;

procedure TFigure.AddScatterPlot(X: TMultiArray; PlotLabel: string; PlotType: integer);
begin
  AddPlot(X, 'points pt ' + IntToStr(PlotType), PlotLabel);
end;

procedure TFigure.Show;
var
  LegendPositionStr, OutStr: string;
  i: integer;
begin
  case LegendPosition of
    lpLeftTop:
      LegendPositionStr := 'left top';
    lpLeftBottom:
      LegendPositionStr := 'left bottom';
    lpRightTop:
      LegendPositionStr := 'right top';
    lpRightBottom:
      LegendPositionStr := 'right bottom';
    lpOutside:
      LegendPositionStr := 'outside';
  end;

  FigureScript.Add('set term qt size 800, 600;');
  FigureScript.Add(Format('set terminal qt title ''%s'';', [FigureTitle]));
  FigureScript.Add(Format('set xlabel ''%s'';', [XLabel]));
  FigureScript.Add(Format('set ylabel ''%s'';', [YLabel]));
  FigureScript.Add(Format('set key %s;', [LegendPositionStr]));
  FigureScript.Add('plot');

  FigureScript.Add(PlotScript.Text);

  RunCommand('gnuplot -persist -e "' + FigureScript.Text + '"', [], OutStr);
  for i := 1 to PlotCount do
    DeleteFile(Format('__MAT_TMP_%d__', [i]));
end;

end.

