function TUIwelcomeMessage(ctrl::AbstractDict)
    msg = "r: Read data files"*TUIcheck(ctrl,"load")*"\n"*
    "m: Specify the method"*TUIcheck(ctrl,"method")*"\n"*
    "t: Tabulate the samples\n"*
    "s: Mark mineral standards"*TUIcheck(ctrl,"standards")*"\n"*
    "g: Mark reference glasses"*TUIcheck(ctrl,"glass")*"\n"*
    "v: View and adjust each sample\n"*
    "p: Process the data"*TUIcheck(ctrl,"process")*"\n"*
    "e: Export the results\n"*
    "l: Logs and templates\n"*
    "o: Options\n"*
    "u: Update\n"*
    "c: Clear\n"*
    "x: Exit\n"*
    "?: Help"
    return msg
end
function TUIshowMethods(ctrl::AbstractDict)
    methods = _PT["methods"].method
    msg = "1. concentrations\n"
    for i in eachindex(methods)
        msg *= string(i+1)*": "*methods[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUIinternalMessage(ctrl::AbstractDict)
    msg = "Choose an internal standard from the following list of channels:\n"
    channels = getChannels(ctrl["run"])
    for i in eachindex(channels)
        msg *= string(i)*". "*channels[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUImineralMessage(ctrl::AbstractDict)
    msg = "Automatically set the concentration of the internal standard " *
        "by selecting one of the following minerals, or specify a value manually:\n"
    minerals = collect(keys(_PT["stoichiometry"]))
    for i in eachindex(minerals)
        msg *= string(i)*". "*minerals[i]*"\n"
    end
    msg *= "m. manual\n"
    return msg
end

function TUIcolumnMessage(ctrl::AbstractDict)
    msg = "Choose from the following list of channels:\n"
    labels = names(getSignals(ctrl["run"][1]))
    for i in eachindex(labels)
        msg *= string(i)*". "*labels[i]*"\n"
    end
    msg *= "and select the channels corresponding to "*
    "the following isotopes or their proxies:\n"
    P, D, d = getPDd(ctrl["method"])
    msg *= P *", "* D *", "* d *"\n"
    msg *= "Specify your selection as a "*
    "comma-separated list of numbers:"
    return msg
end

function TUIchooseStandardMessage(ctrl::AbstractDict)
    msg = "Choose one of the following standards:\n"
    standards = collect(keys(_PT["refmat"][ctrl["method"]]))
    for i in eachindex(standards)
        msg *= string(i)*": "*standards[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUIchooseGlassMessage(ctrl::AbstractDict)
    msg = "Choose one of the following reference glasses:\n"
    glasses = collect(keys(_PT["glass"]))
    for i in eachindex(glasses)
        msg *= string(i)*": "*glasses[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUIaddByPrefixMessage(ctrl::AbstractDict)
    msg = "Specify the prefix of the " * ctrl["cache"] *
        " measurements (? for help, x to exit):"
    return msg
end

function TUIaddByNumberMessage(ctrl::AbstractDict)
    msg = "Select the " * ctrl["cache"] * " measurements " *
        "with a comma-separated list of numbers " *
        "(? for help, x to exit):"
    return msg
end

function TUIratioMessage(ctrl::AbstractDict)
    if haskey(ctrl,"channels")
        channels = collect(values(ctrl["channels"]))
    else
        channels = names(ctrl["run"][1].dat)[3:end]
    end
    msg = "Choose one of the following denominators:\n"
    for i in 1:length(channels)
        msg *= string(i)*": "*channels[i]*"\n"
    end
    msg *= "or\n"
    msg *= "n: No denominator. Plot the raw signals\n"
    msg *= "?: Help"
end

function TUIsetNblankMessage(ctrl::AbstractDict)
    msg = "Enter a non-negative integer (current value = "*
    string(ctrl["options"]["blank"])*", ? for help, x to exit):"
    return msg
end

function TUIsetNdriftMessage(ctrl::AbstractDict)
    msg = "Enter a non-negative integer (current value = "*
    string(ctrl["options"]["drift"])*", ? for help, x to exit)",
    return msg
end

function TUIsetNdownMessage(ctrl::AbstractDict)
    msg = "Enter a non-negative integer (current value = "*
    string(ctrl["options"]["down"])*", ? for help, x to exit)",
    return msg
end
