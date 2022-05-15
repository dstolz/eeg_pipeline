classdef enAnalysisState < uint8
    enumeration
        SETUP       (1)
        READY       (2)
        START       (3)
        PROCESSING  (4)
        PAUSED      (5)
        RESUME      (6)
        STOP        (7)
        STOPPING    (8)
        FINISHED    (9)
        ERROR       (255)
    end
    
    methods (Static)
        function s = list()
            s = saeeg.enAnalysisState(0:9);
        end
    end
end