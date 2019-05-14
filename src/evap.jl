module Evap
using ModelingToolkit

# @register Base.ifelse(cond, a, b)

function petpt(msalb, srad, tmax, tmin, xhlai, eo)
    td = (0.6*tmax)+(0.4*tmin)
    if (xhlai <= 0.0)
        albedo = msalb
    else
        albedo = 0.23-((0.23-msalb)*exp(-((0.75*xhlai))))
    end
    slang = srad*23.923
    eeq = (slang*(0.000204-(0.000183*albedo)))*(td+29.0)
    if (tmax > 35.0)
        eo = eeq*(((tmax-35.0)*0.05)+1.1)
    else
        eo = eeq*1.1
    end
    if (tmax < 5.0)
        eo = (eeq*0.01)*exp((0.18*(tmax+20.0)))
    else
        eo = eo
    end
    eo = max(eo, 0.0001)
end

op_ifelse(op, a, b) = (op) * a + (1-op) * b
# op_ifelse(op::Operation, a, b) = Operation(ifelse, [op, a,b])

function petpt′(msalb, srad, tmax, tmin, xhlai, eo)
    td = (0.6*tmax)+(0.4*tmin)
    albedo = op_ifelse(xhlai <= 0, msalb, 0.23-((0.23-msalb)*exp(-((0.75*xhlai)))))
    slang = srad*23.923
    eeq = (slang*(0.000204-(0.000183*albedo)))*(td+29.0)
    eo = op_ifelse(tmax > 35, eeq*(((tmax-35.0)*0.05)+1.1), 1.1eeq)
    eo = op_ifelse(tmax < 5, (eeq*0.01)*exp((0.18*(tmax+20.0))), eo)
    eo = max(eo, 0.0001)
end




function petasce(canht, doy, msalb, meevp, srad, tdew, tmax, tmin, windht, windrun, xhlai, xlat, xelev, eo)
    tavg = (tmax+tmin)/2.0
    patm = 101.3*(((293.0-(0.0065*xelev))/293.0)^5.26)
    psycon = 0.000665*patm
    udelta = (2503.0*exp(((17.27*tavg)/(tavg+237.3))))/((tavg+237.3)^2.0)
    emax = 0.6108*exp(((17.27*tmax)/(tmax+237.3)))
    emin = 0.6108*exp(((17.27*tmin)/(tmin+237.3)))
    es = (emax+emin)/2.0
    ea = 0.6108*exp(((17.27*tdew)/(tdew+237.3)))
    rhmin = max(20.0, min(80.0, ((ea/emax)*100.0)))
    if (xhlai <= 0.0)
        albedo = msalb
    else
        albedo = 0.23
    end
    rns = (1.0-albedo)*srad
    pie = π #3.14159265359
    dr = 1.0+(0.033*cos((((2.0*pie)/365.0)*doy)))
    ldelta = 0.409*sin(((((2.0*pie)/365.0)*doy)-1.39))
    ws = acos(-(((1.0*tan(((xlat*pie)/180.0)))*tan(ldelta))))
    ra1 = (ws*sin(((xlat*pie)/180.0)))*sin(ldelta)
    ra2 = (cos(((xlat*pie)/180.0))*cos(ldelta))*sin(ws)
    ra = (((24.0/pie)*4.92)*dr)*(ra1+ra2)
    rso = (0.75+(2e-05*xelev))*ra
    ratio = srad/rso
    if (ratio < 0.3)
        ratio = 0.3
    else
        ratio = ratio
    end
    if (ratio > 1.0)
        ratio = 1.0
    else
        ratio = ratio
    end
    fcd = (1.35*ratio)-0.35
    tk4 = (((tmax+273.16)^4.0)+((tmin+273.16)^4.0))/2.0
    rnl = ((4.901e-09*fcd)*(0.34-(0.14*sqrt(ea))))*tk4
    rn = rns-rnl
    g = 0.0
    windsp = (((windrun*1000.0)/24.0)/60.0)/60.0
    wind2m = windsp*(4.87/log(((67.8*windht)-5.42)))
    cn = 0.0
    cd = 0.0
    if (meevp == "A")
        cd = 0.38
    else
        cd = cd
    end
    if (meevp == "A")
        cn = 1600.0
    else
        cn = cn
    end
    if (meevp == "G")
        cd = 0.34
    else
        cd = cd
    end
    if (meevp == "G")
        cn = 900.0
    else
        cn = cn
    end
    refet = ((0.408*udelta)*(rn-g))+(((psycon*(cn/(tavg+273.0)))*wind2m)*(es-ea))
    refet = refet/(udelta+(psycon*(1.0+(cd*wind2m))))
    refet = max(0.0001, refet)
    skc = 0.8
    kcbmin = 0.3
    kcbmax = 1.2
    if (xhlai <= 0.0)
        kcb = 0.0
    else
        kcb = max(0.0, (kcbmin+((kcbmax-kcbmin)*(1.0-exp(-(((1.0*skc)*xhlai)))))))
    end
    wnd = max(1.0, min(wind2m, 6.0))
    cht = max(0.001, canht)
    kcmax = 0.0
    if (meevp == "A")
        kcmax = max(1.0, (kcb+0.05))
    else
        kcmax = kcmax
    end
    if (meevp == "G")
        kcmax = max((1.2+(((0.04*(wnd-2.0))-(0.004*(rhmin-45.0)))*((cht/3.0)^0.3))), (kcb+0.05))
    else
        kcmax = kcmax
    end
    if (kcb <= kcbmin)
        fc = 0.0
    else
        fc = ((kcb-kcbmin)/(kcmax-kcbmin))^(1.0+(0.5*canht))
    end
    fw = 1.0
    few = min((1.0-fc), fw)
    ke = max(0.0, min((1.0*(kcmax-kcb)), (few*kcmax)))
    eo = (kcb+ke)*refet
    eo = max(eo, 0.0001)
end

function petasce′(canht, doy, msalb, meevp, srad, tdew, tmax, tmin, windht, windrun, xhlai, xlat, xelev, eo)
    tavg = (tmax+tmin)/2.0
    patm = 101.3*(((293.0-(0.0065*xelev))/293.0)^5.26)
    psycon = 0.000665*patm
    udelta = (2503.0*exp(((17.27*tavg)/(tavg+237.3))))/((tavg+237.3)^2.0)
    emax = 0.6108*exp(((17.27*tmax)/(tmax+237.3)))
    emin = 0.6108*exp(((17.27*tmin)/(tmin+237.3)))
    es = (emax+emin)/2.0
    ea = 0.6108*exp(((17.27*tdew)/(tdew+237.3)))
    rhmin = max(20.0, min(80.0, ((ea/emax)*100.0)))
    albedo = op_ifelse(xhlai <= 0.0, msalb, 0.23)
    rns = (1.0-albedo)*srad
    pie = π #3.14159265359
    dr = 1.0+(0.033*cos((((2.0*pie)/365.0)*doy)))
    ldelta = 0.409*sin(((((2.0*pie)/365.0)*doy)-1.39))
    ws = acos(-(((1.0*tan(((xlat*pie)/180.0)))*tan(ldelta))))
    ra1 = (ws*sin(((xlat*pie)/180.0)))*sin(ldelta)
    ra2 = (cos(((xlat*pie)/180.0))*cos(ldelta))*sin(ws)
    ra = (((24.0/pie)*4.92)*dr)*(ra1+ra2)
    rso = (0.75+(2e-05*xelev))*ra
    ratio = srad/rso
    ratio = op_ifelse(ratio < 0.3, 0.3, ratio)
    ratio = op_ifelse(ratio > 1.0, 1.0, ratio)
    fcd = (1.35*ratio)-0.35
    tk4 = (((tmax+273.16)^4.0)+((tmin+273.16)^4.0))/2.0
    rnl = ((4.901e-09*fcd)*(0.34-(0.14*sqrt(ea))))*tk4
    rn = rns-rnl
    g = 0.0
    windsp = (((windrun*1000.0)/24.0)/60.0)/60.0
    wind2m = windsp*(4.87/log(((67.8*windht)-5.42)))
    cn = 0.0
    cd = 0.0
    if (meevp == "A")
        cd = 0.38
    else
        cd = cd
    end
    if (meevp == "A")
        cn = 1600.0
    else
        cn = cn
    end
    if (meevp == "G")
        cd = 0.34
    else
        cd = cd
    end
    if (meevp == "G")
        cn = 900.0
    else
        cn = cn
    end
    refet = ((0.408*udelta)*(rn-g))+(((psycon*(cn/(tavg+273.0)))*wind2m)*(es-ea))
    refet = refet/(udelta+(psycon*(1.0+(cd*wind2m))))
    refet = max(0.0001, refet)
    skc = 0.8
    kcbmin = 0.3
    kcbmax = 1.2
    kcb = op_ifelse(xhlai <= 0.0,
                    0.0,
                    max(0.0,
                        (kcbmin+
                         ((kcbmax-
                           kcbmin)*
                          (1.0-
                           exp(-(((1.0*skc)*
                                  xhlai))))))))
    wnd = max(1.0, min(wind2m, 6.0))
    cht = max(0.001, canht)
    kcmax = 0.0
    if (meevp == "A")
        kcmax = max(1.0, (kcb+0.05))
    else
        kcmax = kcmax
    end
    if (meevp == "G")
        kcmax = max((1.2+(((0.04*(wnd-2.0))-(0.004*(rhmin-45.0)))*((cht/3.0)^0.3))), (kcb+0.05))
    else
        kcmax = kcmax
    end
    fc = op_ifelse(kcb <= kcbmin, 0.0,((kcb-kcbmin)/(kcbmax-kcbmin))^(1.0+(0.5*canht)))
    fw = 1.0
    few = min((1.0-fc), fw)
    ke = max(0.0, min((1.0*(kcmax-kcb)), (few*kcmax)))
    eo = (kcb+ke)*refet
    eo = max(eo, 0.0001)
end
end

using ModelingToolkit

@variables msalb srad tmax tmin xhlai eo
ptexpr = Evap.petpt′(msalb, srad, tmax, tmin, xhlai, eo)
@show vals = (msalb = 1, srad = 1 , tmax = 6, tmin=0, xhlai=1, eo=1)
@show Symbolic.apply(ptexpr, vals)

valsASCE = (canht = 1, doy=15,
            msalb=5, meevp=0.2, srad=1,
            tdew=24, tmax=6, tmin=0,
            windht=10, windrun=2,
            xhlai=1, xlat=0.36, xelev=200,
            eo=1)

meevp = "A"


@variables(canht, doy, msalb, srad, tdew, tmax, tmin,
           windht, windrun, xhlai, xlat, xelev, eo)

asceex = Evap.petasce′(canht, doy, msalb, meevp, srad, tdew,
                  tmax, tmin, windht, windrun, xhlai,
                       xlat, xelev, eo)

@show asceval = Symbolic.apply(asceex, valsASCE)

# using autodiff

# function petptfunc(x)
#     vals = (msalb = 1, srad = 1 , tmax = 6, tmin=0, xhlai=x[1], eo=1);
#     Evap.petpt(vals...)
# end

using ForwardDiff

ptgrad = map(0:0.05:1) do x
    xarr = [1,x,6,0,1,1]
    (input=xarr, value=Evap.petpt(xarr...), gradient=ForwardDiff.gradient(t -> Evap.petpt(t...), xarr))
end

function gradsweep(m, dim::Int, x, perturbations)
    mgrad = map(perturbations) do δ
        xarr = copy(x)
        xarr[dim] += δ
        (input=tuple(xarr...),
         value=m(xarr...),
         gradient=ForwardDiff.gradient(t -> m(t...), xarr)[dim])
    end
    return mgrad
end

x₀= [0.0,1,6,0,1,1]
@show gradsweep(Evap.petpt, 1, x₀, 0:0.05:1)

using Statistics
using LinearAlgebra

function linearity(m, dim::Int, x, perturbations)
    y = gradsweep(m, dim, x, perturbations)
    yvals = map(x->x.value, y)
    grads = map(x->x.gradient, y)
    return (dim=dim,ȳ = mean(yvals), ∇̄=mean(grads), σ_∇=std(grads)/mean(grads))
end

function linearity(m, x₀)
    ForwardDiff.hessian(x->m(x...), x₀) |> diag
end


lintests = map(1:6) do i
    linearity(Evap.petpt, i, x₀, 0:0.05:1)
end
@show lintests
@show linearity(Evap.petpt, x₀)

valsASCE = (canht = 1, doy=15,
            msalb=1, meevp=0.2, srad=1,
            tdew=24, tmax=6, tmin=0,
            windht=10, windrun=2,
            xhlai=1, xlat=0.36, xelev=200,
            eo=1)
@show Evap.petasce′(valsASCE...)
ascehess = linearity(Evap.petasce′, collect(valsASCE))
@show ascehess
# lintests2 = map(1:6) do i
#     linearity(Evap.petpt, i, [0.0,2,6,0,1,1], 0:0.05:1)
# end
# @show lintests2

# lintests3 = map(1:6) do i
#     linearity(Evap.petpt, i, [1.0,1,1,1,1,1], 0:0.05:1)
# end
# @show lintests3
curvatur = map(1:50) do i
    x = collect(valsASCE) .+ randn(Float64, 14)
    y = try
        linearity(Evap.petasce′, x) ./ x
    catch ex ;
        @info "failure"
    end
end |>
    y-> filter(x->x!=nothing, y) |>
    mean 
