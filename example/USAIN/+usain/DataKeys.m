classdef DataKeys
    % Collection of all DataKey-objects used in USAIN.
    % Put into an empty class with constant properties to facilitate tab-completion.
    % Do not use `runner.DataKey('MyKey')`! Use `usain.DataKeys.MyKey` instead.

    properties (Constant)
        % Constant properties, but intentionally written in UpperSnakeCase and not UPPER_CAMEL_CASE
        ConditionCollection = runner.DataKey('ConditionCollection')
        ExternalFlsLoadsData = runner.DataKey('ExternalFlsLoadsData', true)
        ExternalS1LoadsData = runner.DataKey('ExternalS1LoadsData', true)
        ExternalUlsLoadsData = runner.DataKey('ExternalUlsLoadsData', true)
        FlangeModel = runner.DataKey('FlangeModel')
        FlangeNeckScfSummaryFile = runner.DataKey('FlangeNeckScfSummaryFile', true)
        FlangeNeckScfOutputData = runner.DataKey('FlangeNeckScfOutputData', true)
        Inputs = runner.DataKey('Inputs')
        SelectedConditionCollection = runner.DataKey('SelectedConditionCollection')
        SelectedModel = runner.DataKey('SelectedModel')
        SelectedModelInputFilePath = runner.DataKey('SelectedModelInputFilePath')
        Sgre2SummaryFilePath = runner.DataKey('Sgre2SummaryFilePath', true)
        SourceInputFilePath = runner.DataKey('SourceInputFilePath')
        StructuralModel = runner.DataKey('StructuralModel')  % TODO: Make data-key optional (after WPSSD-5639)
        StructuralModelOutputPath = runner.DataKey('StructuralModelOutputPath', true)
        TimeStamp = runner.DataKey('TimeStamp')
        UsnFilePath = runner.DataKey('UsnFilePath')
        hasFeasibleDesign = runner.DataKey('hasFeasibleDesign')
        doSwitchLtoT = runner.DataKey('doSwitchLtoT')
    end

end
