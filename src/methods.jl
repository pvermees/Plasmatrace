function Base.getproperty(obj::Run, attr::Symbol)
    return getfield(obj,attr)
end
function Base.getproperty(obj::Crun, attr::Symbol)
    if attr in propertynames(Crun)
        return getfield(obj,attr)
    else 
        return getfield(obj.control,attr)
    end
end
function Base.getproperty(obj::Prun, attr::Symbol)
    if attr in propertynames(Prun)
        return getfield(obj,attr)
    elseif attr in propertynames(Control)
        return getfield(obj.control,attr)
    else 
        return getfield(obj.pars,attr)
    end
end

function Base.setproperty!(obj::Run, attr::Symbol, newVal)
    setproperty!(obj,attr,newVal)
end
function Base.setproperty!(obj::Crun, attr::Symbol, newVal)
    if attr in propertynames(Crun)
        setproperty!(obj,attr,newVal)
    else 
        setproperty!(obj.control,attr,newVal)
    end
end
function Base.setproperty!(obj::Prun, attr::Symbol, newVal)
    if attr in propertynames(Prun)
        setproperty!(obj,attr,newVal)
    elseif attr in propertynames(Control)
        setproperty!(obj.control,attr,newVal)
    else 
        setproperty!(obj.pars,attr,newVal)
    end
end
