unit supervised.naivebayes;

{$mode objfpc}{$H+}

interface

uses
  common, multiarray, numerik;

type
  TNaiveBayesClassifier = class(TBaseSupervisedLearner)
  private
    MuPerClass, SigPerClass: array of TMultiArray;
    SubsetPerClass: array of TMultiArray;
    UniqueClasses: TMultiArray;
    function PXGivenY(X: TMultiArray; y: longint): TMultiArray;
  public
    function Fit(X, y: TMultiArray): TBaseSupervisedLearner; override;
    function Predict(X: TMultiArray): TMultiArray; override;
  end;

implementation

{ TNaiveBayesClassifier }

function TNaiveBayesClassifier.Fit(X, y: TMultiArray): TBaseSupervisedLearner;
var
  i: integer;
begin
  UniqueClasses := Unique(y).UniqueValues;
  SetLength(SubsetPerClass, UniqueClasses.Size);
  SetLength(MuPerClass, UniqueClasses.Size);
  SetLength(SigPerClass, UniqueClasses.Size);

  for i := 0 to UniqueClasses.Size - 1 do
  begin
    SubsetPerClass[i] := X.SliceBool([y = i]);
    MuPerClass[i] := Mean(SubsetPerClass[i], 0, True);
    SigPerClass[i] := Sum((SubsetPerClass[i] - MuPerClass[i]) ** 2, 0) /
      (SubsetPerClass[i].Shape[0] - 1);
  end;

  Exit(self);
end;

function TNaiveBayesClassifier.PXGivenY(X: TMultiArray; y: longint): TMultiArray;
var
  Tmp: TMultiArray;
begin
  Tmp := 1 / ((Sqrt(2 * Pi * SigPerClass[y]+0.0001)));
  Tmp := Tmp * Exp((-(X - MuPerClass[y]) ** 2) / (2 * SigPerClass[y]));
  Exit(ReduceAlongAxis(tmp, @Multiply, 1, True));
end;

function TNaiveBayesClassifier.Predict(X: TMultiArray): TMultiArray;
var
  i: integer;
  PXGivenYArr: array of TMultiArray = nil;
begin
  SetLength(PXGivenYArr, UniqueClasses.Size);
  for i := 0 to UniqueClasses.Size - 1 do
    PXGivenYArr[i] := PXGivenY(X, i).T;
  Exit(ArgMax(VStack(PXGivenYArr).T, 1));
end;

end.
