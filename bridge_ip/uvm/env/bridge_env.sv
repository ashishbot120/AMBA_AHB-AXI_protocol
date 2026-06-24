
class bridge_env extends uvm_env;
    `uvm_component_utils(bridge_env)

    ahb_agent  ahb_agt;
    axi_agent  axi_agt;
    scoreboard scb;

    function new(string name = "bridge_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ahb_agt = ahb_agent::type_id::create("ahb_agt", this);
        axi_agt = axi_agent::type_id::create("axi_agt", this);
        scb     = scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        ahb_agt.monitor.ap.connect(scb.ahb_imp);
        axi_agt.monitor.ap.connect(scb.axi_imp);
    endfunction

endclass
