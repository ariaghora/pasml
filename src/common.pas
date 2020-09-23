unit common;

{$mode objfpc}{$H+}

interface

uses
  Classes, multiarray;

type
  TBaseUnsupervisedLearner = class
  public
    function Fit(X: TMultiArray): TBaseUnsupervisedLearner; virtual; abstract;
    function Predict(X: TMultiArray): TMultiArray; virtual; abstract;
  end;

  TBaseSupervisedLearner = class
  public
    function Fit(X, y: TMultiArray): TBaseSupervisedLearner; virtual; abstract;
    function Predict(X: TMultiArray): TMultiArray; virtual; abstract;
  end;

implementation

end.

