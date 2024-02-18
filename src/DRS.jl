function DRS!(pd::run;method::T,channels::Vector{T}) where T<:AbstractString
    DRSmethod!(pd,method=method)
    DRSchannels!(pd,channels=channels)
end
export DRS!

function DRSmethod!(pd::run;method::T) where {T<:AbstractString}
    if (method=="LuHf")
        isotopes = ["Lu176","Hf176","Hf177"]
        gain = log(0.682)
    else
        PTerror("UnknownMethod")
    end
    setMethod!(pd,method)
    setIsotopes!(pd,isotopes)
    setGainPar!(pd,gain)
end

function DRSchannels!(pd::run;channels::Vector{T}) where T<:AbstractString
    isotopes = getIsotopes(pd)
    if size(channels,1)==size(isotopes,1)
        setChannels!(pd,channels)
    else
        PTerror("isochanmismatch")
    end
end
