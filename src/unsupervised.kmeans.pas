unit unsupervised.kmeans;

{$mode objfpc}{$H+}

interface

uses
  multiarray, Math, numerik, common;

type
  TKMeans = class(TBaseUnsupervisedLearner)
  private
    Means: TMultiArray;
  public
    Centroids: TMultiArray;
    NumCluster: longint;
    NIter: longint;
    constructor Create(ANumCluster: longint; ANumIter: longint = 10);
    function Fit(X: TMultiArray): TKMeans; override;
    function Predict(X: TMultiArray): TMultiArray; override;
  end;

implementation

{ TKMeans }

constructor TKMeans.Create(ANumCluster: longint; ANumIter: longint);
begin
  NumCluster := ANumCluster;
  NIter := ANumIter;
end;

function TKMeans.Fit(X: TMultiArray): TKMeans;
var
  i, c, row, col: longint;
  preds: TMultiArray;
  NewCentroidArr: array of TMultiArray = nil;
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
