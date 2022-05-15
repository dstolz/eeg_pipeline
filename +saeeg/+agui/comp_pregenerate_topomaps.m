classdef comp_pregenerate_topomaps < saeeg.agui.AnalysisGUI
    
    properties
        
    end
    
    methods
        function obj = comp_pregenerate_topomaps(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
            outPathRoot = obj.MasterObj.OutputPath;
            
            pthOut = fullfile(outPathRoot,'CLEANED');
            pthFig = fullfile(outPathRoot,'TOPOFIG');
            
            
            if ~isfolder(pthOut), mkdir(pthOut); end
            if ~isfolder(pthFig), mkdir(pthFig); end
            
            fn = char(Q.CurrentFilename);
            ffnOut = char(fullfile(pthOut,[fn '_CLEANED.mat']));
            ffnFig = char(fullfile(pthFig,[fn '_TOPOFIG.fig']));
            
            if ~Q.OverwriteExisting && exist(ffnOut,'file')
                saeeg.vprintf(1,1,'File already exists, skippping: %s\n',ffnOut)
            else                
                cfg = [];
                cfg.layout  = 'biosemi64.lay';
                cfg.marker  = 'off';
                cfg.shading = 'interp';
                cfg.style   = 'straight';
                cfg.comment = 'no';
                cfg.title   = 'auto';
                
                % create placeholder ffnFig
                f = figure('WindowState','Maximized');
                savefig(f,ffnFig);
                
                saeeg.vprintf(1,'Loading components data from "%s" ...',Q.CurrentFilename)
                load(Q.CurrentFile,'comp');
                
                cfg.component = 1:length(comp.label);
                
                ft_warning off FieldTrip:getdimord:warning_dimord_could_not_be_determined
                ft_topoplotIC(cfg,comp)
                ft_warning on FieldTrip:getdimord:warning_dimord_could_not_be_determined
                
                f.CreateFcn = @gui_toggle_component;
                
                h = findobj(f,'-property','ButtonDownFcn');
                set(h,'ButtonDownFcn',@gui_toggle_component);
                ax = findobj(f,'type','axes');
                
                f.CloseRequestFcn = @gui_clean_components;
                f.Name = Q.CurrentFilename;
                f.Tag = 'TOPO';
                f.Pointer = 'hand';
                
                f.UserData.compToBeRejected = false(size(ax));
                f.UserData.cfg = cfg;
                f.UserData.comp = comp;
                f.UserData.compcfg = comp.cfg;
                f.UserData.ffnTopoFig = ffnFig;
                f.UserData.ffnOut = ffnOut;
                f.UserData.TimeStamp = now;
                
                drawnow
                
                saeeg.vprintf(1,'Saving figure "%s" ...',ffnFig)
                savefig(f,ffnFig);
                
                delete(f)
            end
            
            Q.mark_completed;
            
            Q.start_next;
            
        end
        
        function create_gui(obj)
            
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = {30,'1x'};
            
            
            h = uitextarea(g);
            h.Layout.Column = [1 2];
            h.Layout.Row = 2;
            h.Value = 'NOTE: This function does not have any customizable parameters at the momment. Just run as is.';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.Editable = 'off';
            h.HorizontalAlignment = 'center';
            

            
        end
        
        
    end
    
    
end