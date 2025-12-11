classdef ConditContainer < matlab.mixin.SetGet & logging.Config

    properties
        Thread UsainUtils.ThreadRequirements
        MdlAppl UsainUtils.BoltForceModelApplicability
        Uls UsainUtils.UltimateLimitState
        UlsJpn UsainUtils.UltimateLimitStateJpn
        PreloadLoss UsainUtils.SlsPretensionLoss
        Gapping UsainUtils.FlangeGapping
        Fls UsainUtils.FatigueLimitState
        NeckScf UsainUtils.FlangeNeckScf
    end

    methods

        function Obj = ConditContainer()
            Obj.Thread      = UsainUtils.ThreadRequirements();
            Obj.MdlAppl     = UsainUtils.BoltForceModelApplicability();
            Obj.Uls         = UsainUtils.UltimateLimitState();
            Obj.UlsJpn      = UsainUtils.UltimateLimitStateJpn();
            Obj.PreloadLoss = UsainUtils.SlsPretensionLoss();
            Obj.Gapping     = UsainUtils.FlangeGapping();
            Obj.Fls         = UsainUtils.FatigueLimitState(1);
            Obj.NeckScf     = UsainUtils.FlangeNeckScf();
        end

    end
end
