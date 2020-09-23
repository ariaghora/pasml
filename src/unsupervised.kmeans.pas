unit unsupervised.kmeans;

{$mode objfpc}{$H+}

interface

uses
  multiarray, Math, numerik, SysUtils;

type
  TKMeans = class
  private
    Mins, Maxes, Means: TMultiArray;
  public
    Centroids: TMultiArray;
    NumCluster: longint;
    NIter: longint;
    constructor Create(ANumCluster: longint; ANumIter: longint = 10);
    function Fit(X: TMultiArray): TKMeans;
    function Predict(X: TMultiArray): TMultiArray;
  end;

implementation


{ TKMeans }

constructor TKMeans.Create(ANumCluster: longint; ANumIter: longint);
begin
  NumCluster := ANumCluster;
  NIter := ANumIter;
end;


function Any(X: TMultiArray; Axis: longint = -1): TMultiArray;
var
  idx: TLongVectorArr;
  vals: TSingleVector;
  i: longint;
begin
  if Axis + 1 > X.NDims then
    raise Exception.Create('Axis is greater than X.NDims.');

  SetLength(idx, X.NDims);
  for i := 0 to High(idx) do
    idx[i] := [];

  if Axis = -1 then
    Exit(Sum(X) > 0);

  SetLength(vals, X.Shape[Axis]);
  for i := 0 to X.Shape[Axis] - 1 do
  begin
    idx[Axis] := i;
    Vals[i] := Any(X[idx]).Item;
  end;
  Exit(Vals);
end;

function TKMeans.Fit(X: TMultiArray): TKMeans;
var
  i, c, row, col: longint;
  preds: TMultiArray;
  NewCentroidArr: array of TMultiArray;
begin
  Means := Mean(X, 0);

  SetLength(NewCentroidArr, NumCluster);

  { Random centroid initialization }
  Centroids := AllocateMultiArray(NumCluster * X.Shape[1]);
  Centroids := Centroids.Reshape([NumCluster, X.Shape[1]]);
  for row := 0 to NumCluster - 1 do
    for col := 0 to X.Shape[1] - 1 do
      Centroids.Put([row, col], Math.RandG(Means[[col]].Item, 1));

  { Main kmeans algorithm iteration }
  for i := 0 to NIter - 1 do
  begin
    preds := Predict(X);
    for c := 0 to NumCluster - 1 do
      NewCentroidArr[c] := Mean(X.SliceBool([preds = c]), 0, True);

    { update centroids }
    Centroids := VStack(NewCentroidArr);
  end;

  Exit(self);
end;

function TKMeans.Predict(X: TMultiArray): TMultiArray;
begin
  Exit(ArgMin(EuclideanDistances(X, Centroids), 1));
end;

end.
