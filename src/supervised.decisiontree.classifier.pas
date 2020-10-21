unit supervised.decisiontree.classifier;

{$mode objfpc}{$H+}

interface

uses
  Math, fgl, common, multiarray, numerik;

type
  TSplitsMap = specialize TFPGMap<single, TSingleVector>;
  TSingleVectorArr = array of TSingleVector;

  TSplitData = record
    DataAbove, DataBelow: TMultiArray;
    LabelAbove, LabelBelow: TMultiArray;
  end;

  TBestSplitResult = record
    SplitCol: longint;
    SplitVal: single;
  end;

  TTreeNode = class
    SplitCol: longint;
    SplitVal: single;
    IsLeaf: boolean;
    ClassLabel: single;
    Left: TTreeNode;
    Right: TTreeNode;
  public
    constructor Create(AIsLeaf: boolean=False);
  end;
  TNodeList = specialize TFPGObjectList<TTreeNode>;

  TDecisionTreeClassifier = class(TBaseSupervisedLearner)
  private
    MaxDepth: integer;
    MinSampleSplit: integer;
    NumClasses: integer;
    NumFeatures: integer;
    Tree: TTreeNode;
    function CalcEntropy(y: TMultiArray): single;
    function FindBestSplit(X, y: TMultiArray;
      APotentialSplitArr: TSingleVectorArr): TBestSplitResult;
    function CalcOverallEntropy(yBelow, yAbove: TMultiArray): single;
    function ClassifyData(y: TMultiArray): TTreeNode;
    function ClassifyExample(X: TMultiArray; ATree: TTreeNode): TTreeNode;
    function GetPotentialSplits(X: TMultiArray): TSingleVectorArr;
    function IsPure(y: TMultiArray): boolean;
    function SplitData(X, y: TMultiArray; Col: integer; Thresh: single): TSplitData;
    function GrowTree(X, y: TMultiArray; counter: integer = 0): TTreeNode;
  public
    constructor Create(AMaxDepth: integer=-1; AMinSampleSplit: integer=2);
    destructor Destroy; override;
    function Fit(X, y: TMultiArray): TBaseSupervisedLearner; override;
    function Predict(X: TMultiArray): TMultiArray; override;
  end;

implementation

{ TTreeNode }

var
  NodeList: TNodeList;

constructor TTreeNode.Create(AIsLeaf: boolean);
begin
  IsLeaf := AIsLeaf;
  NodeList.Add(self);
end;

{ TDecisionTreeClassifier }

function TDecisionTreeClassifier.CalcEntropy(y: TMultiArray): single;
var
  i: integer;
  UniqueLabel: TMultiArray;
  probs: TSingleVector = nil;
begin
  UniqueLabel := Unique(y).UniqueValues;
  SetLength(probs, UniqueLabel.Size);
  for i := 0 to UniqueLabel.Size - 1 do
    probs[i] := (Sum(y = UniqueLabel.Get(i)) / y.Size).Item;

  Exit(Sum(TMultiArray(probs) * -numerik.Log2(probs)).Item);
end;

function TDecisionTreeClassifier.FindBestSplit(X, y: TMultiArray;
  APotentialSplitArr: TSingleVectorArr): TBestSplitResult;
var
  OverallEntropy: single = MaxSingle;
  v, bsVal, CurrentOverallEntropy: single;
  c, bsCol: integer;
  spl: TSplitData;
begin
  for c := 0 to NumFeatures - 1 do
    for v in APotentialSplitArr[c] do
    begin
      spl := SplitData(X, y, c, v);
      CurrentOverallEntropy := CalcOverallEntropy(spl.LabelBelow, spl.LabelAbove);
      if CurrentOverallEntropy <= OverallEntropy then
      begin
        OverallEntropy := CurrentOverallEntropy;
        bsCol := c;
        bsVal := v;
      end;
    end;
  Result.SplitCol := bsCol;
  Result.SplitVal := bsVal;
end;

function TDecisionTreeClassifier.CalcOverallEntropy(yBelow, yAbove: TMultiArray): single;
var
  pBelow, pAbove: single;
begin
  pBelow := yBelow.Shape[0] / (yBelow.Shape[0] + yAbove.Shape[0]);
  pAbove := yAbove.Shape[0] / (yBelow.Shape[0] + yAbove.Shape[0]);
  Exit(pBelow * CalcEntropy(yBelow) + pAbove * CalcEntropy(yAbove));
end;

function TDecisionTreeClassifier.ClassifyData(y: TMultiArray): TTreeNode;
var
  UniqueLabels, UniqueLabelCounts: TMultiArray;
  UniqueRes: TUniqueResult;
  ClassLabel: single;
begin
  UniqueRes := Unique(y, -1, True);
  UniqueLabels := UniqueRes.UniqueValues;
  UniqueLabelCounts := UniqueRes.Counts;
  ClassLabel := UniqueLabels.Get(Round(ArgMax(UniqueLabelCounts).Item));

  Result := TTreeNode.Create(True);
  Result.ClassLabel := ClassLabel;
end;

function TDecisionTreeClassifier.ClassifyExample(X: TMultiArray;
  ATree: TTreeNode): TTreeNode;
var
  Answer: TTreeNode;
begin
  if X[[0, ATree.SplitCol]].Item <= ATree.SplitVal then
    Answer := ATree.Left
  else
  begin
    Answer := ATree.Right;
  end;

  if (Answer.Right=nil) and (Answer.Left=nil) then
  begin
    Exit(Answer)
  end
  else
    Exit(ClassifyExample(X, Answer));

end;

function TDecisionTreeClassifier.GetPotentialSplits(X: TMultiArray): TSingleVectorArr;
var
  i, c: integer;
  PotentialSplit, curr, prev: single;
  UniqueVals: TMultiArray;
  PotentialSplitArr: TSingleVectorArr = nil;
begin
  SetLength(PotentialSplitArr, NumFeatures);
  for c := 0 to NumFeatures - 1 do
  begin
    UniqueVals := ArraySort(Unique(X[[_ALL_, c]]).UniqueValues);

    SetLength(PotentialSplitArr[c], UniqueVals.Size - 1);
    for i := 1 to High(UniqueVals.GetVirtualData) do
    begin
      curr := UniqueVals.Get(i);
      prev := UniqueVals.Get(i - 1);
      PotentialSplit := (curr + prev) / 2;
      PotentialSplitArr[c][i - 1] := PotentialSplit;
    end;
  end;
  Exit(PotentialSplitArr);
end;

function TDecisionTreeClassifier.IsPure(y: TMultiArray): boolean;
begin
  Exit(Unique(y).UniqueValues.Size = 1);
end;

function TDecisionTreeClassifier.SplitData(X, y: TMultiArray; Col: integer;
  Thresh: single): TSplitData;
var
  DataToSplit: TMultiArray;
begin
  DataToSplit := X[[_ALL_, Col]];
  Result.DataBelow := X.SliceBool([DataToSplit <= Thresh]);
  Result.DataAbove := X.SliceBool([DataToSplit > Thresh]);
  Result.LabelBelow := y.SliceBool([DataToSplit <= Thresh]);
  Result.LabelAbove := y.SliceBool([DataToSplit > Thresh]);
end;

function TDecisionTreeClassifier.GrowTree(X, y: TMultiArray;
  counter: integer): TTreeNode;
var
  spl: TSplitData;
  bSpl: TBestSplitResult;
  SubTree, YesNode, NoNode: TTreeNode;
begin
  if (IsPure(y)) or (X.Shape[0] < MinSampleSplit) or (counter = MaxDepth) then
  begin
    Exit(ClassifyData(y));
  end
  else
  begin
    bSpl := FindBestSplit(X, y, GetPotentialSplits(X));
    spl := SplitData(X, y, bSpl.SplitCol, bSpl.SplitVal);

    SubTree := TTreeNode.Create(False);

    counter := counter + 1;
    YesNode := GrowTree(spl.DataBelow, spl.LabelBelow, counter);
    NoNode := GrowTree(spl.DataAbove, spl.LabelAbove, counter);

    SubTree.Left := YesNode;
    SubTree.Right := NoNode;
    SubTree.SplitCol := bSpl.SplitCol;
    SubTree.SplitVal := bSpl.SplitVal;
  end;
  Exit(SubTree);
end;

constructor TDecisionTreeClassifier.Create(AMaxDepth: integer;
  AMinSampleSplit: integer);
begin
  MaxDepth := AMaxDepth;
  MinSampleSplit := AMinSampleSplit;
end;

destructor TDecisionTreeClassifier.Destroy;
begin
  NodeList.Free;
  inherited Destroy;
end;

function TDecisionTreeClassifier.Fit(X, y: TMultiArray): TBaseSupervisedLearner;
begin
  NumClasses := Unique(y).UniqueValues.Size;
  NumFeatures := X.Shape[1];

  NodeList := TNodeList.Create(True);
  Tree := GrowTree(X, y);

  Exit(Self);
end;

function TDecisionTreeClassifier.Predict(X: TMultiArray): TMultiArray;
var
  res: TSingleVector = nil;
  i: longint;
begin
  SetLength(res, X.Shape[0]);
  for i := 0 to X.Shape[0] - 1 do
    res[i] := ClassifyExample(X[[i]], Tree).ClassLabel;
  Exit(res);
end;

end.
