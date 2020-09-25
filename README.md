# PasML
A collection of machine learning algorithms for object pascal

## Numerik compatibility
```pascal
Dataset := ReadCSV('datasets/iris.csv');
X := Dataset[[_ALL_, [0, 1, 2, 3]]];
y := Dataset[[_ALL_, 4]];
```

## Clustering 
### Implemented algorithms
|Model|Notes|
|---|---|
|K-Means||

```pascal
kmeans := TKMeans.Create(3);
kmeans.Fit(X);
WriteLn('Clustering result:');
PrintMultiArray(kmeans.Predict(X));
```

## Classification 
### Implemented algorithms
|Model|Notes|
|---|---|
|Naive Bayes|Gaussian naive bayes|
|Decision Tree|C4.5 implementation|

```pascal
nb := TNaiveBayesClassifier.Create;
nb.Fit(X, y);
pred := nb.Predict(X);

WriteLn('Accuracy:');
PrintMultiArray(Mean(pred = Ravel(y)));
```


## Note
- PasML requires [numerik](https://github.com/ariaghora/numerik), so you should install it first. Refer to numerik installation [guide](https://github.com/ariaghora/numerik#installation).
- If you want to work with neural network, please check [noe](https://github.com/ariaghora/noe) framework that was designed specifically for this task.
