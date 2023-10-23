function setDRS!(pd::run;method="LuHf",refmat="Hogsbo")
    setMethod!(pd,method=method)
    setAB!(pd,method=method,refmat=refmat)
end

function setMethod!(pd::run;method::String)
    if (method=="LuHf")
        channels = ["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"]
    else
        PTerror("UnknownMethod")
    end
    ctrl = getControl(pd)
    if isnothing(ctrl)
        ctrl = control(nothing,nothing,channels)
    else
        ctrl.channels = channels
    end
    setControl!(pd;ctrl=ctrl)
end
