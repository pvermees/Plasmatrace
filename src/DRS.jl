function setDRS!(pd::run;method="LuHf",refmat="Hogsbo")
    if (method=="LuHf")
        channels = ["Hf176 -> 258","Hf178 -> 260","Lu175 -> 175"]
    end
    AB = getAB(pd,refmat)
    setControl!(pd,control(AB[1],AB[2],channels))
end
