unit supervised.mlp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, common, multiarray, noe, noe.neuralnet, noe.optimizer;

type
  TMLP = class(TBaseSupervisedLearner)
    fHiddenLayerSizes: TLongVector;
    fMaxIter: longint;
    Model: TNNModel;
    constructor Create(HiddenLayerSizes: array of integer;
      MaxIter: longint = 200); virtual;
    destructor Destroy; override;
  end;

  TMLPRegressor = class(TMLP)
    function Fit(X, y: TMultiArray): TBaseSupervisedLearner; override;
    function Predict(X: TMultiArray): TMultiArray; override;
  end;

implementation

{ TMLPRegressor }

function TMLPRegressor.Fit(X, y: TMultiArray): TBaseSupervisedLearner;
var
  i: integer;
  opt: TOptAdam;
  pred, loss: TTensor;
begin
  Model.AddLayer(TLayerDense.Create(X.Shape[1], fHiddenLayerSizes[0]));
  Model.AddLayer(TLayerReLU.Create);
  for i := 0 to High(fHiddenLayerSizes) - 1 do
  begin
    Model.AddLayer(TLayerDense.Create(fHiddenLayerSizes[i], fHiddenLayerSizes[i + 1]));
    Model.AddLayer(TLayerReLU.Create);
  end;
  Model.AddLayer(TLayerDense.Create(fHiddenLayerSizes[High(fHiddenLayerSizes)],
    y.Shape[1]));

  opt := TOptAdam.Create(Model.Params);
  for i := 0 to fMaxIter do
  begin
    pred := Model.Eval(X);
    loss := Mean(Sqr(pred - y));
    loss.Backward();
    opt.Step;
    loss.ZeroGrad;

    if loss.Data.Item < 1e-5 then
      Break;
  end;

  opt.Free;
  Exit(self);
end;

function TMLPRegressor.Predict(X: TMultiArray): TMultiArray;
begin
  Exit(Model.Eval(X));
end;

{ TMLP }

constructor TMLP.Create(HiddenLayerSizes: array of integer; MaxIter: longint);
begin
  Model := TNNModel.Create;
  fHiddenLayerSizes := HiddenLayerSizes;
  fMaxIter := MaxIter;
end;

destructor TMLP.Destroy;
begin
  Model.Free;
  inherited Destroy;
end;

end.
