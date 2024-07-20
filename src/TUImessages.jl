function TUIshowMethods(ctrl::AbstractDict)
    methods = _PT["methods"].method
    msg = ""
    for i in eachindex(methods)
        msg *= string(i)*": "*methods[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUIcolumnMessage(ctrl::AbstractDict)
    msg = "Choose from the following list of channels:\n"
    labels = names(getDat(ctrl["run"][1]))
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
