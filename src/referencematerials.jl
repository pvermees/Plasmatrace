function getAB(refmat::String="Hogsbo")
    if refmat=="Hogsbo"
        t = (1029,1.7)
        y0 = (3.55,0.05)
        lambda = (1.867e-05,8e-08)
    end
    DP = exp(lambda[1]*t[1])-1
    x0 = 1/DP
    A = y0[1]
    B = -A/x0
    [A,B]
end
