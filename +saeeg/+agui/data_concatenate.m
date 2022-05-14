classdef data_concatenate < saeeg.agui.AnalysisGUI
    
    properties
        
    end
    
    methods
        function obj = data_concatenate(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
                
            orderTokenIdx     = obj.handles.orderTokenIdx.Value;
            orderRegSymbol    = string(obj.handles.orderRegSymbol.Value);
            delimiter         = obj.handles.delimiter.Value;

            pathOut = fullfile(obj.MasterObj.OutputPath,'MERGED');
            pathIn  = fileparts(Q.CurrentFile);
            
            toBeMerged = merge_data_files(pathIn,orderTokenIdx,orderRegSymbol,delimiter);
            
            
            if ~isfolder(pathOut), mkdir(pathOut); end
            
            saeeg.vprintf(1,'Will attempt to merge %d groups of files\n',length(toBeMerged))
            for i = 1:length(toBeMerged)
                saeeg.vprintf(1,'Merging %d of %d groups',i,length(toBeMerged))
                
                if numel(toBeMerged{i}) < 2
                    saeeg.vprintf(0,1,'Mulitple files not found. No merging performed for this file!: "%s"',char(toBeMerged{i}))
                    continue
                end
                
                data = [];
                fn = cell(size(toBeMerged{i}));
                for j = 1:length(toBeMerged{i})
                    [~,fn{j},~] = fileparts(toBeMerged{i}{j});
                    saeeg.vprintf(1,'\t> %d/%d: "%s"',j,length(toBeMerged{i}),fn{j})
                    if j == 1
                        load(toBeMerged{i}{j},'data');
                    else
                        m = load(toBeMerged{i}{j},'data');
                        data.trial = {[data.trial{1}, m.data.trial{1}]};
                    end
                end
                
                data.time  = {(0:length(data.trial{1})-1.)/data.fsample};
                data.sampleinfo = [1 length(data.time{1})];
                
                
                s = string(split(fn,delimiter));
                s(1,orderTokenIdx) = join(s(:,orderTokenIdx)',"_");
                fnOut = join(s(1,:),delimiter);
                fnOut = fnOut + "_MERGED.mat";
                ffnOut = fullfile(pathOut,fnOut);
                
                if ~Q.OverwriteExisting && exist(ffnOut,'file')
                    saeeg.vprintf(0,1,'Merged file already exists, skippping: %s',fnOut)
                    continue
                end
                
                saeeg.vprintf(1,'Saving "%s"',fnOut)
                save(ffnOut,'data');
            end
            
            Q.mark_completed(1:length(Q.Queue));
        end
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = repmat({30},1,5);
            
            
            h = uitextarea(g);
            h.Layout.Column = [1 2];
            h.Layout.Row = [1 2];
            h.Value = 'NOTE: THIS FUNCTION WORKS ON ENTIRE DIRECTORY NO MATTER HOW MANY FILES ARE SELECTED.';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.Editable = 'off';
            h.HorizontalAlignment = 'center';
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 3;
            h.Text = 'Order Token Index:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            
            h = uieditfield(g,'numeric');
            h.Layout.Column = 2;
            h.Layout.Row = 3;
            h.Value = getpref('saeeg_agui','data_concatenate_orderTokenIdx',5);
            h.ValueDisplayFormat = '%d';
            h.RoundFractionalValues = true;
            h.HorizontalAlignment = 'center';
            h.Limits = [1 100];
            obj.handles.orderTokenIdx = h;
                        
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 4;
            h.Text = 'Order Regexp Symbol:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            
            h = uieditfield(g);
            h.Layout.Column = 2;
            h.Layout.Row = 4;
            h.HorizontalAlignment = 'center';
            h.Value = getpref('saeeg_agui','data_concatenate_orderRegSymbol','\w*');
            obj.handles.orderRegSymbol = h;
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 5;
            h.Text = 'Delimiter:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            
            h = uieditfield(g);
            h.Layout.Column = 2;
            h.Layout.Row = 5;
            h.HorizontalAlignment = 'center';
            h.Value = getpref('saeeg_agui','data_concatenate_delimiter','_');
            obj.handles.delimiter = h;
        end
        
        
    end
    
end