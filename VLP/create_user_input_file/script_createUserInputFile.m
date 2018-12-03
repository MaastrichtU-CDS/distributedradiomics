clear
clc
userInput.maxIter = 1000;
addpath('json')
%% adjust values here
% sites for training

% set site ID----------------------------------------------ZW
userInput.trainSitesID = [24];
% sites for testing
userInput.testSitesID = [24];
% sparql query & endpointKey for sparql
userInput.sparqlQuery ='PREFIX ncit:<http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#> PREFIX roo: <http://www.cancerdata.org/roo/> PREFIX ro: <http://www.radiomics.org/RO/> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX xsd: <http://www.w3.org/2001/XMLSchema#> PREFIX d2rq: <http://www.wiwiss.fu-berlin.de/suhl/bizer/D2RQ/0.1#> SELECT ?patient ?Fstat_energy ?Fmorph_comp_2 ?Frlm_rlnu ?Fszm_glnu ?vitalStatusLabel ?survivalValue WHERE {?patient a ncit:C16960 . ?patient ro:0010217 ?featureObj1 . FILTER contains(str(?featureObj1), "Fstat"). ?featureObj1 roo:P100042 ?Fstat_energy. ?patient ro:0010217 ?featureObj2 . FILTER contains(str(?featureObj2), "Fmorph"). ?featureObj2 roo:P100042 ?Fmorph_comp_2. ?patient ro:0010217 ?featureObj3 . FILTER contains(str(?featureObj3), "Frlm"). ?featureObj3 roo:P100042 ?Frlm_rlnu. ?patient ro:0010217 ?featureObj4 . FILTER contains(str(?featureObj4), "Fszm"). ?featureObj4 roo:P100042 ?Fszm_glnu. ?patient roo:P100028 ?vitalStatusObj . ?vitalStatusObj a ?vitalStatusType . FILTER(?vitalStatusType!=ncit:C25717) . ?vitalStatusType rdfs:label ?vitalStatusLabel . ?patient roo:P100026 ?survivalObj . ?survivalObj roo:P100042 ?survivalValue .}';
% userInput.sparqlQuery =''
userInput.endpointKey = 'DistRadiomicsData';
% randomization seed (yet unused)
userInput.dataSplitSeed = 1;

% for each feature in userInput.featureNames: if the feature is a
% categorical with more than 2 categories, provide the vector of possible
% values (needs to be numerical) For binary and continuous variables, use [].
% Note for future updates: categoricalFeatureRange is a bit of a misnomer - consider renaming.

% %----------------------------Cox regression model
% -------- name of outcome variable
userInput.outcomeName = {'survivalValue'};
% -------- names of four features
userInput.featureNames = {'Fstat.energy','Fmorph.comp.2','Frlm.rlnu','Fszm.glnu','vitalStatusLabel'};
userInput.categoricalFeatureRange = cell(1,length(userInput.featureNames));
userInput.categoricalFeatureRange{1} = []; % 4 features
userInput.categoricalFeatureRange{2} = []; 
userInput.categoricalFeatureRange{3} = []; 
userInput.categoricalFeatureRange{4} = [];
userInput.categoricalFeatureRange{5} = [];

% determine imputation ('mode' or 'mean') for each feature in userInput.featureNames
% example for manual assignment:
% userInput.imputationType = {'mode','mean','mode'};
% automatic assignment based on userInput.categoricalFeatureRange:
for i_features = 1:length(userInput.featureNames)
    if isempty(userInput.categoricalFeatureRange{i_features}) % if it is continuous
    userInput.imputationType{i_features} = 'mean';
    else
    userInput.imputationType{i_features} = 'mode'; % if it is not continuous
    end
end

% Lagrangian parameter
userInput.rho = 1;
% relaxation parameter in z update
userInput.alpha = 1.5;
% weight in the SVM objective
userInput.lambda = 0.01;

% parameters for convergence criterion (Boyd's settings: userInput.absTol = 10^-4; userInput.relTol = 10^-2;)
userInput.absTol = 10^-2;
userInput.relTol = 10^-2;

% names of all variables, automatically constructed from earlier input
userInput.variableNames = [userInput.featureNames userInput.outcomeName];
% loop to calculate the number of coefficients for x,u,z
numberOfCoefficients = 1; % start with 1 for the 'intercept'
for i_catFeatRange = 1:length(userInput.categoricalFeatureRange)
    if isempty(userInput.categoricalFeatureRange{i_catFeatRange})
        numberOfCoefficients = numberOfCoefficients + 1;
    else
        numberOfCoefficients = numberOfCoefficients + (numel(userInput.categoricalFeatureRange{i_catFeatRange}) - 1); % you create (numel()- 1) dummy variables
    end 
end
userInput.x = zeros(numberOfCoefficients,1);
userInput.u = zeros(numberOfCoefficients,1);
userInput.z = zeros(numberOfCoefficients,1);

% create json string from userInput struct and save to text file
jsonString = savejson('',userInput, 'FileName', 'userInputFile.txt');