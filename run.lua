require('torch')
require('nn')
require('image')
require('paths')

require ('pl')
require ('camera')

torch.setdefaulttensortype('torch.FloatTensor')

title = 'Deep Visualization Tool with Torch'

options = lapp[[
   -e,--eye                (default 231)                      size of the input
   -m,--mean               (default 0.46423)                  mean for preprocessiong
   -w,--std                (default 0.24273)                  std for preprocessing
   -m,--network            (default overfeat.net)             pre-trained model
   -l,--labels             (default overfeat_label)       labels of categories
]]

-- If you do no have any models, pretrained overfeat model will be fetched
-- (https://github.com/jhjin/overfeat-torch)

-- global variable
state = {}
state.rawFrame  = torch.Tensor()
state.classes   = {}

-- get dependent files
if options.network == 'overfeat.net' then 
   if not paths.filep('overfeat.net') then
     os.execute([[
       git clone https://github.com/jhjin/overfeat-torch
       cd overfeat-torch
       echo "torch.save('overfeat.net', net)" >> run.lua
       . install.sh && th run.lua && mv model.net .. && cd ..
     ]])
   end
end



if options.labels == 'overfeat_label' then
   if not paths.filep('overfeat_label.lua') then
      os.execute('wget https://raw.githubusercontent.com/jhjin/overfeat-torch/master/overfeat_label.lua')
   end
end

state.network = torch.load(options.network)
state.label = require(options.labels)


state.network_table = {}
local counter = 0
for i=1, #state.network.modules do
   if (state.network.modules[i].weight) then
      counter = counter+1 
      local layer_name = state.network.modules[i].__typename..tostring(counter)
      local finding = {name = layer_name , i=i}
      table.insert(state.network_table, finding)
      table.insert(state.classes, layer_name)
   end
end



-- setup GUI (external UI file)
require 'qt'
require 'qtwidget'
require 'qtuiloader'


widget  = qtuiloader.load('g.ui')
painter = qt.QtLuaPainter(widget.frame)
display = require 'display'
ui      = require 'ui'


display.begin()
