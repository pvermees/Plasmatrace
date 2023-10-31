function setMethod!(pd::run;method::String,channels::Vector{String})
    if (method=="LuHf")
        isotopes = ["Lu176","Hf177","Hf176"]
    else
        PTerror("UnknownMethod")
    end
    if size(channels,1)!=size(isotopes,1) PTerror("isochanmismatch") end
    ctrl = getControl(pd)
    if isnothing(ctrl)
        ctrl = control(method,nothing,nothing,isotopes,channels)
    else
        setIsotopess!(ctrl,isotopes)
        setChannels!(ctrl,channels)
    end
    setControl!(pd;ctrl=ctrl)
end
export setMethod!
