package MMV


  package BaseClasses
    record FAN_per
      extends Buildings.Fluid.Movers.Data.Generic(final powerOrEfficiencyIsHydraulic = false, etaHydMet = Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate, power(V_flow = {0, 0.5, 1.146, 1.2284, 1.4055, 1.781, 2.08, 2.459, 2.992, 3.314, 3.886, 4.2, 4.54, 4.907, 5.219, 5.328}, P = {3439.013, 4044.170, 5079.775528603263, 5229.612, 5569.096, 6355.762, 6829.138, 7398.072, 8082.568, 8346.338, 8708.903, 8783.022, 8758.611, 8772.183, 8512.259, 8232.685}), pressure(V_flow = {0, 0.5, 1.146, 1.2284, 1.4055, 1.781, 2.08, 2.459, 2.992, 3.314, 3.886, 4.2, 4.54, 4.907, 5.219, 5.328}, dp = {2070, 2069, 2068, 2067, 2065.496, 2061.539, 2002.076, 1908.168, 1735.311, 1594.127, 1320.892, 1147.55, 942.638, 732.135, 508.435, 398.783}));
      // V_flow → m³/s; dp → Pa; P → W
    end FAN_per;

    /// V_flow: [m3/s]
    extends Modelica.Icons.BasesPackage;

    record Pump_per "Pump data for a Wilo Cronoline-IL 80/220-4/4 pump"
      // within Buildings.Fluid.Movers.Data.Pumps.Wilo;
      // V_flow → m³/s; dp → Pa
      extends Buildings.Fluid.Movers.Data.Generic(final powerOrEfficiencyIsHydraulic = false, etaHydMet = Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate, power(V_flow = {0.00303454715219, 0.00578898225957, 0.00863678804855, 0.0113912231559, 0.0146125116713, 0.0181605975724, 0.0214285714286, 0.0248366013072, 0.0274042950514, 0.0282446311858}, P = {1905.29339941, 2202.03582759, 2548.86483304, 2812.07908132, 3146.06691483, 3435.07911022, 3592.75276695, 3710.09774539, 3774.78991597, 3793.34692457}), pressure(V_flow = {0.00303454715219, 0.00578898225957, 0.00863678804855, 0.0113912231559, 0.0146125116713, 0.0181605975724, 0.0214285714286, 0.0248366013072, 0.0274042950514, 0.0282446311858}, dp = {168215.17064, 166653.242326, 164291.843595, 161128.282627, 154367.77774, 142807.085577, 128439.498542, 108468.216086, 92889.3102384, 86895.3009775}));
      annotation(
        defaultComponentPrefixes = "parameter",
        defaultComponentName = "per",
        Documentation(info = "<html>
    <p>Data from: <a href=\"http://productfinder.wilo.com/com/en/c000000220003ab4800010023/_000000100002c2550002003a/product.html\">http://productfinder.wilo.com/com/en/c000000220003ab4800010023/_000000100002c2550002003a/product.html</a></p>
    <p>See <a href=\"modelica://Buildings.Fluid.Movers.Data.Pumps.Wilo.Stratos25slash1to6\">Buildings.Fluid.Movers.Data.Pumps.Wilo.Stratos25slash1to6 </a>for more information about how the data is derived. </p>
    </html>", revisions = "<html>
    <ul>
    <li>
    March 29, 2023, by Hongxiang Fu:<br/>
    Deleted angular speed parameters with the unit rpm.
    This is for
    <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/1704\">IBPSA, #1704</a>.
    </li>
    <li>
    October 14, 2021, by Hongxiang Fu:<br/>
    Rewrote the statements using <code>use_powerCharacteristic</code>
    to support the implementation of
    <a href=\"Modelica://Buildings.Fluid.Movers.BaseClasses.Euler\">
    <code>Buildings.Fluid.Movers.BaseClasses.Euler</code></a>.
    This is for
    <a href=\"https://github.com/lbl-srg/modelica-buildings/issues/2668\">#2668</a>.
    </li>
    <li>
    June 01, 2017, by Iago Cupeiro:
    <br/>
    Changed data link to English version
    </li>
    <li>
    February 17, 2016, by Michael Wetter:<br/>
    Updated parameter names for
    <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/396\">#396</a>.
    </li>
    <li>
    December 12, 2014, by Michael Wetter:<br/>
    Added <code>defaultComponentPrefixes</code> and
    <code>defaultComponentName</code> annotations.
    </li>
    <li>April 22, 2014
        by Filip Jorissen:<br/>
           Initial version
    </li>
    </ul>
    </html>"));
    end Pump_per;

    model fanTest
      replaceable package MediumA = Buildings.Media.Air "Medium for air";
      Buildings.Fluid.Movers.SpeedControlled_y fan(redeclare package Medium = MediumA, energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyState, redeclare AirBalancing.BaseClasses.FAN_per per, addPowerToMedium = false, inputType = Buildings.Fluid.Types.InputType.Continuous) annotation(
        Placement(transformation(origin = {16, -40}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Sources.Constant const(k = 0.8) annotation(
        Placement(transformation(origin = {-74, -28}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Fluid.FixedResistances.PressureDrop res(redeclare package Medium = MediumA, m_flow_nominal = 0.6, dp_nominal = 300) annotation(
        Placement(transformation(origin = {2, 6}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Fluid.MixingVolumes.MixingVolume vol(redeclare package Medium = MediumA, m_flow_nominal = 0.6, V = 100, nPorts = 2) annotation(
        Placement(transformation(origin = {58, 16}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(const.y, fan.y) annotation(
        Line(points = {{-63, -28}, {16, -28}}, color = {0, 0, 127}));
      connect(fan.port_a, res.port_b) annotation(
        Line(points = {{6, -40}, {-22, -40}, {-22, 6}, {-8, 6}}, color = {0, 127, 255}));
      connect(res.port_a, vol.ports[1]) annotation(
        Line(points = {{12, 6}, {58, 6}}, color = {0, 127, 255}));
      connect(vol.ports[2], fan.port_b) annotation(
        Line(points = {{58, 6}, {58, -40}, {26, -40}}, color = {0, 127, 255}));
    end fanTest;

    partial package IconFMU "Icon for FMU"
      extends Modelica.Icons.Package;
      annotation(
        Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(textColor = {128, 128, 128}, extent = {{-90, -90}, {90, 90}}, textString = "fmu")}));
    end IconFMU;

    model DamperTest "Dampers with constant pressure difference and varying control signal."
      extends Modelica.Icons.Example;
      package Medium = Buildings.Media.Air "Medium model for air";
      Buildings.Fluid.Actuators.Dampers.Exponential res(redeclare package Medium = Medium, use_inputFilter = false, dpDamper_nominal = 0.1524, m_flow_nominal = 0.05, k1 = 0.45, a = -0.5934, b = 11.28564) "A damper with quadratic relationship between m_flow and dp" annotation(
        Placement(transformation(origin = {-2, -38}, extent = {{0, 30}, {20, 50}})));
      Buildings.Fluid.Sources.Boundary_pT sou(redeclare package Medium = Medium, p(displayUnit = "Pa") = 101355, T = 293.15, nPorts = 4) "Pressure boundary condition" annotation(
        Placement(transformation(origin = {-36, 2}, extent = {{-60, -10}, {-40, 10}})));
      Buildings.Fluid.Sources.Boundary_pT sin(redeclare package Medium = Medium, nPorts = 4) "Pressure boundary condition" annotation(
        Placement(transformation(origin = {0, 2}, extent = {{94, -10}, {74, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant con(k = 1.0) annotation(
        Placement(transformation(origin = {-24, 58}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(res.port_a, sou.ports[1]) annotation(
        Line(points = {{-2, 2}, {-76, 2}}, color = {0, 127, 255}));
      connect(res.port_b, sin.ports[1]) annotation(
        Line(points = {{18, 2}, {74, 2}}, color = {0, 127, 255}));
      connect(con.y, res.y) annotation(
        Line(points = {{-12, 58}, {8, 58}, {8, 14}}, color = {0, 0, 127}));
      annotation(
        experiment(Tolerance = 1e-6, StopTime = 1.0),
        __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/Fluid/Actuators/Dampers/Examples/Damper.mos" "Simulate and plot"),
        Documentation(info = "<html>
      <p>
      Test model for exponential and linear air dampers.
      The air dampers are connected to models for constant inlet and outlet
      pressures. The control signal of the dampers is a ramp.
      </p>
      </html>", revisions = "<html>
      <ul>
      <li>
      March 21, 2017 by David Blum:<br/>
      Added Linear damper models <code>lin</code>, <code>preIndFrom_dp</code>, and <code>preInd</code>.
      </li>
      <li>
      July 20, 2007 by Michael Wetter:<br/>
      First implementation.
      </li>
      </ul>
      </html>"));
    end DamperTest;

    model ResTest "Dampers with constant pressure difference and varying control signal."
      extends Modelica.Icons.Example;
      package Medium = Buildings.Media.Air "Medium model for air";
      Buildings.Fluid.Sources.Boundary_pT sou(redeclare package Medium = Medium, p(displayUnit = "Pa") = 101385, T = 293.15, nPorts = 1) "Pressure boundary condition" annotation(
        Placement(transformation(origin = {-36, 2}, extent = {{-60, -10}, {-40, 10}})));
      Buildings.Fluid.Sources.Boundary_pT sin(redeclare package Medium = Medium, nPorts = 1) "Pressure boundary condition" annotation(
        Placement(transformation(origin = {0, 2}, extent = {{94, -10}, {74, 10}})));
      Buildings.Fluid.FixedResistances.PressureDrop res(redeclare package Medium = Medium, dp_nominal = 30, m_flow_nominal = 0.3) annotation(
        Placement(transformation(origin = {-8, 2}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(sou.ports[1], res.port_a) annotation(
        Line(points = {{-76, 2}, {-18, 2}}, color = {0, 127, 255}));
      connect(res.port_b, sin.ports[1]) annotation(
        Line(points = {{2, 2}, {74, 2}}, color = {0, 127, 255}));
      annotation(
        experiment(Tolerance = 1e-6, StopTime = 1.0),
        __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/Fluid/Actuators/Dampers/Examples/Damper.mos" "Simulate and plot"),
        Documentation(info = "<html>
      <p>
      Test model for exponential and linear air dampers.
      The air dampers are connected to models for constant inlet and outlet
      pressures. The control signal of the dampers is a ramp.
      </p>
      </html>", revisions = "<html>
      <ul>
      <li>
      March 21, 2017 by David Blum:<br/>
      Added Linear damper models <code>lin</code>, <code>preIndFrom_dp</code>, and <code>preInd</code>.
      </li>
      <li>
      July 20, 2007 by Michael Wetter:<br/>
      First implementation.
      </li>
      </ul>
      </html>"));
    end ResTest;

    model RoomLeakage "Room leakage model"
      extends Buildings.BaseClasses.BaseIcon;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component" annotation(
        choicesAllMatching = true);
      parameter Modelica.Units.SI.Volume VRoo "Room volume";
      parameter Boolean use_windPressure = false "Set to true to enable wind pressure" annotation(
        Evaluate = true);
      Buildings.Fluid.FixedResistances.PressureDrop res(redeclare package Medium = Medium, dp_nominal = 50, m_flow_nominal = 1) "Resistance model" annotation(
        Placement(transformation(extent = {{20, -10}, {40, 10}})));
      Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare package Medium = Medium) annotation(
        Placement(transformation(extent = {{90, -10}, {110, 10}})));
      Buildings.Fluid.Sources.Outside_CpLowRise amb(redeclare package Medium = Medium, nPorts = 1, s = s, azi = azi, Cp0 = if use_windPressure then 0.6 else 0) annotation(
        Placement(transformation(extent = {{-60, -10}, {-40, 10}})));
      Buildings.BoundaryConditions.WeatherData.Bus weaBus "Bus with weather data" annotation(
        Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      Buildings.Fluid.Sensors.MassFlowRate senLeakFlo(redeclare package Medium = Medium, allowFlowReversal = true) "Sensor for mass flow rate" annotation(
        Placement(transformation(extent = {{10, 10}, {-10, -10}}, rotation = 180, origin = {-10, 0})));
      Modelica.Blocks.Math.Gain ACHInf(k = 1/VRoo/1.2*3600, y(unit = "1/h")) "Air change per hour due to infiltration" annotation(
        Placement(transformation(extent = {{12, 30}, {32, 50}})));
      parameter Real s "Side ratio, s=length of this wall/length of adjacent wall";
      parameter Modelica.Units.SI.Angle azi "Surface azimuth (South:0, West:pi/2)";
    equation
      connect(res.port_b, port_b) annotation(
        Line(points = {{40, 6.10623e-16}, {55, 6.10623e-16}, {55, 1.16573e-15}, {70, 1.16573e-15}, {70, 5.55112e-16}, {100, 5.55112e-16}}, color = {0, 127, 255}));
      connect(amb.weaBus, weaBus) annotation(
        Line(points = {{-60, 0.2}, {-80, 0.2}, {-80, 5.55112e-16}, {-100, 5.55112e-16}}, color = {255, 204, 51}, thickness = 0.5, smooth = Smooth.None));
      connect(amb.ports[1], senLeakFlo.port_a) annotation(
        Line(points = {{-40, 6.66134e-16}, {-20, 6.66134e-16}, {-20, 7.25006e-16}}, color = {0, 127, 255}, smooth = Smooth.None));
      connect(senLeakFlo.port_b, res.port_a) annotation(
        Line(points = {{5.55112e-16, -1.72421e-15}, {10, -1.72421e-15}, {10, 6.10623e-16}, {20, 6.10623e-16}}, color = {0, 127, 255}, smooth = Smooth.None));
      connect(senLeakFlo.m_flow, ACHInf.u) annotation(
        Line(points = {{-10, 11}, {-10, 40}, {10, 40}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(
        Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-80, 40}, {0, -40}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, fillColor = {0, 127, 255}), Rectangle(extent = {{20, 12}, {80, -12}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {192, 192, 192}), Rectangle(extent = {{20, 6}, {80, -6}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 127, 255}), Line(points = {{-100, 0}, {-80, 0}}, color = {0, 0, 255}), Line(points = {{0, 0}, {20, 0}}, color = {0, 0, 255}), Line(points = {{80, 0}, {90, 0}}, color = {0, 0, 255})}),
        Documentation(info = "<html>
    <p>
    Room leakage.
    </p></html>", revisions = "<html>
    <ul>
    <li>
    July 20, 2007 by Michael Wetter:<br/>
    First implementation.
    </li>
    </ul>
    </html>"));
    end RoomLeakage;

    model InternalGains3 "Combine occupancy, misc bias (W/m2), and heater power (W) into {rad, con, lat} heat gains (W)"
      // Nominal densities per floor area
      parameter Real qOcc_nominal_Wm2(min = 0) = 0 "Occupant nominal gain per floor area (W/m2)";
      parameter Real qMis_Wm2(min = 0) = 0 "Misc/unmeasured gain per floor area (W/m2)";
      parameter Real qHea_Wm2(min = 0) = 15.9 "Heater/plug/light gain per floor area (W/m2)";
      // Fraction inputs, use 1 if the source is constant
      Modelica.Blocks.Interfaces.RealInput occFra "Occupancy fraction 0..1" annotation(
        Placement(transformation(origin = {-197, 33}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, 80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput misFra "Misc fraction 0..1" annotation(
        Placement(transformation(origin = {-197, -15}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, 6}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput heaFra "Heater fraction 0..1" annotation(
        Placement(transformation(origin = {-197, -53}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, -70}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Math.MatrixGain gaiOcc(K = qOcc_nominal_Wm2*[0.4; 0.4; 0.2]) "Matrix gain to split up heat gain in radiant, convective and latent gain" annotation(
        Placement(transformation(origin = {-50, 34}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Routing.Multiplex mulOcc(n = 1) annotation(
        Placement(transformation(origin = {-98, 34}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Routing.DeMultiplex3 demOcc annotation(
        Placement(transformation(origin = {8, 34}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Routing.Multiplex mulMis(n = 1) annotation(
        Placement(transformation(origin = {-98, -16}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.MatrixGain gaiMis(K = qMis_Wm2*[0.5; 0.5; 0]) annotation(
        Placement(transformation(origin = {-48, -16}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Routing.DeMultiplex3 demMis annotation(
        Placement(transformation(origin = {10, -16}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add3 addRad "Radiant heat gain" annotation(
        Placement(transformation(origin = {72, 46}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Routing.Multiplex mulHea(n = 1) annotation(
        Placement(transformation(origin = {-98, -54}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.MatrixGain gaiHea(K = qHea_Wm2*[0.5; 0.5; 0]) annotation(
        Placement(transformation(origin = {-48, -54}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Routing.DeMultiplex3 demHea annotation(
        Placement(transformation(origin = {10, -54}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add3 addCon "Convective heat gain" annotation(
        Placement(transformation(origin = {74, -16}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add3 addLat "Latent heat gain" annotation(
        Placement(transformation(origin = {74, -62}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yRad annotation(
        Placement(transformation(origin = {146, 46}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 76}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yCon annotation(
        Placement(transformation(origin = {144, -16}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 6}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yLat annotation(
        Placement(transformation(origin = {144, -62}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -70}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(mulOcc.y, gaiOcc.u) annotation(
        Line(points = {{-87, 34}, {-62, 34}}, color = {0, 0, 127}, thickness = 0.5));
      connect(gaiOcc.y, demOcc.u) annotation(
        Line(points = {{-39, 34}, {-4, 34}}, color = {0, 0, 127}, thickness = 0.5));
      connect(mulMis.y, gaiMis.u) annotation(
        Line(points = {{-87, -16}, {-60, -16}}, color = {0, 0, 127}, thickness = 0.5));
      connect(gaiMis.y, demMis.u) annotation(
        Line(points = {{-37, -16}, {-2, -16}}, color = {0, 0, 127}, thickness = 0.5));
      connect(occFra, mulOcc.u[1]) annotation(
        Line(points = {{-197, 33}, {-134, 33}, {-134, 34}, {-108, 34}}, color = {0, 0, 127}));
      connect(misFra, mulMis.u[1]) annotation(
        Line(points = {{-197, -15}, {-133, -15}, {-133, -16}, {-108, -16}}, color = {0, 0, 127}));
      connect(heaFra, mulHea.u[1]) annotation(
        Line(points = {{-197, -53}, {-135, -53}, {-135, -54}, {-108, -54}}, color = {0, 0, 127}));
      connect(mulHea.y, gaiHea.u) annotation(
        Line(points = {{-86, -54}, {-60, -54}}, color = {0, 0, 127}, thickness = 0.5));
      connect(gaiHea.y, demHea.u) annotation(
        Line(points = {{-36, -54}, {-2, -54}}, color = {0, 0, 127}, thickness = 0.5));
      connect(demOcc.y1[1], addRad.u1) annotation(
        Line(points = {{20, 42}, {20, 54}, {60, 54}}, color = {0, 0, 127}));
      connect(demMis.y1[1], addRad.u2) annotation(
        Line(points = {{22, -8}, {24, -8}, {24, 46}, {60, 46}}, color = {0, 0, 127}));
      connect(demHea.y1[1], addRad.u3) annotation(
        Line(points = {{22, -46}, {28, -46}, {28, 38}, {60, 38}}, color = {0, 0, 127}));
      connect(demOcc.y2[1], addCon.u1) annotation(
        Line(points = {{20, 34}, {34, 34}, {34, -8}, {62, -8}}, color = {0, 0, 127}));
      connect(demMis.y2[1], addCon.u2) annotation(
        Line(points = {{22, -16}, {62, -16}}, color = {0, 0, 127}));
      connect(demHea.y2[1], addCon.u3) annotation(
        Line(points = {{22, -54}, {34, -54}, {34, -24}, {62, -24}}, color = {0, 0, 127}));
      connect(demOcc.y3[1], addLat.u1) annotation(
        Line(points = {{20, 28}, {54, 28}, {54, -54}, {62, -54}}, color = {0, 0, 127}));
      connect(demMis.y3[1], addLat.u2) annotation(
        Line(points = {{22, -22}, {48, -22}, {48, -62}, {62, -62}}, color = {0, 0, 127}));
      connect(demHea.y3[1], addLat.u3) annotation(
        Line(points = {{22, -60}, {22, -70}, {62, -70}}, color = {0, 0, 127}));
      connect(addRad.y, yRad) annotation(
        Line(points = {{84, 46}, {146, 46}}, color = {0, 0, 127}));
      connect(addCon.y, yCon) annotation(
        Line(points = {{86, -16}, {144, -16}}, color = {0, 0, 127}));
      connect(addLat.y, yLat) annotation(
        Line(points = {{86, -62}, {144, -62}}, color = {0, 0, 127}));
      annotation(
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Text(origin = {-1, 7}, extent = {{-105, 37}, {105, -37}}, textString = "Gains3")}),
        Diagram(coordinateSystem(extent = {{-220, 60}, {180, -80}})));
    end InternalGains3;

    model OACtrl "CO2-based outdoor air (OA) damper control: ramp from yOAMin to yOAMax"
      // ---------------------------------------------------------------------------
      // Outdoor air damper controller (DCV by CO2)
      //
      // What it does:
      // - Computes an "effective ramp start" CO2Start = CO2Set + CO2Db_ppm.
      // - When CO2Meas <= CO2Start  -> OA damper stays at yOAMin.
      // - When CO2Meas >= CO2Max_ppm -> OA damper saturates at yOAMax.
      // - Between those points -> linear ramp from yOAMin to yOAMax.
      //
      // Enable / disable:
      // - If sysOn = true AND winOpen = false: output the computed yOA.
      // - Otherwise: output offDamOA (typically 0, or you can choose yOAMin if needed).
      //
      // Numerical robustness:
      // - limSpan ensures the CO2 ramp span never becomes 0 (avoids divide-by-zero).
      // - limCO2 and limDam limit normalized values and final output to valid ranges.
      // ---------------------------------------------------------------------------
      // Inputs
      Modelica.Blocks.Interfaces.RealInput CO2Meas "Measured zone/return CO2 concentration [ppm]." annotation(
        Placement(transformation(origin = {199, 139}, extent = {{17, -17}, {-17, 17}}), iconTransformation(origin = {120, 50}, extent = {{20, -20}, {-20, 20}})));
      Modelica.Blocks.Interfaces.RealInput CO2Set "CO2 setpoint [ppm]. Typically occupancy/IAQ target." annotation(
        Placement(transformation(origin = {199, 55}, extent = {{17, -17}, {-17, 17}}), iconTransformation(origin = {120, -60}, extent = {{20, -20}, {-20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC allowed to operate). When false, damper is forced to offDamOA." annotation(
        Placement(transformation(origin = {174, -54}, extent = {{20, -20}, {-20, 20}}, rotation = -0), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open / natural ventilation flag (true = open). When true, damper is forced to offDamOA." annotation(
        Placement(transformation(origin = {176, -92}, extent = {{20, -20}, {-20, 20}}, rotation = -0), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Output
      Modelica.Blocks.Interfaces.RealOutput yDamOut "OA damper command (0..1)" annotation(
        Placement(transformation(origin = {-234, -54}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}})));
      // Parameters
      parameter Real CO2Max_ppm = 1000 "CO2 concentration [ppm] at which the OA damper reaches yOAMax (top of ramp).";
      parameter Real yOAMin = 0.10 "Minimum OA damper position (0..1). Used when CO2 is below the ramp start.";
      parameter Real yOAMax = 1.00 "Maximum OA damper position (0..1). Used when CO2 is above CO2Max_ppm.";
      parameter Real CO2Db_ppm = 20 "CO2 deadband/offset [ppm]. Ramp start is shifted to CO2Set + CO2Db_ppm to reduce hunting.";
      parameter Real epsCO2Span = 1 "Minimum CO2 span protection [ppm]. Prevents divide-by-zero if CO2Max_ppm ~= CO2Start.";
      // ---------------------------------------------------------------------------
      // Core CO2 ramp computation
      // ---------------------------------------------------------------------------
      // Effective ramp start = CO2Set + CO2Db_ppm
      Modelica.Blocks.Sources.Constant conCO2Db(k = CO2Db_ppm) "Deadband/offset added to the CO2 setpoint." annotation(
        Placement(transformation(origin = {172, 24}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Add co2Start(k1 = +1, k2 = +1) "CO2Start = CO2Set + CO2Db_ppm. Below this, OA stays at yOAMin." annotation(
        Placement(transformation(origin = {140, 50}, extent = {{10, -10}, {-10, 10}})));
      // Error relative to ramp start: CO2Err = CO2Meas - CO2Start
      Modelica.Blocks.Math.Add co2Err(k1 = +1, k2 = -1) "CO2 error above ramp start: CO2Err = CO2Meas - CO2Start." annotation(
        Placement(transformation(origin = {-4, 134}, extent = {{10, -10}, {-10, 10}})));
      // Span of the CO2 ramp: span = CO2Max_ppm - co2Start
      Modelica.Blocks.Sources.Constant conCO2Max(k = CO2Max_ppm) "CO2Max constant [ppm] defining the top of the ramp." annotation(
        Placement(transformation(origin = {170, 78}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Add co2Span(k1 = +1, k2 = -1) "CO2 ramp span: span = CO2Max_ppm - CO2Start." annotation(
        Placement(transformation(origin = {94, 72}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Nonlinear.Limiter limSpan(uMax = 1e9, uMin = epsCO2Span) "Protect span from becoming too small (avoid divide-by-zero / excessive gain)." annotation(
        Placement(transformation(origin = {60, 72}, extent = {{10, -10}, {-10, 10}})));
      // Normalized CO2 ramp position: norm = (CO2Meas - CO2Start) / span
      Modelica.Blocks.Math.Division divCO2 "Normalized ramp value before limiting: (CO2Meas - CO2Start) / span." annotation(
        Placement(transformation(origin = {26, 94}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Nonlinear.Limiter limNorCO2(uMax = 1, uMin = 0) "Clamp normalized CO2 ramp position to [0,1]." annotation(
        Placement(transformation(origin = {-62, 58}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Sources.Constant conOne(k = 1) annotation(
        Placement(transformation(origin = {60, 100}, extent = {{10, -10}, {-10, 10}})));
      // Damper range: dY = yOAMax - yOAMin
      Modelica.Blocks.Sources.Constant conYMax(k = yOAMax) "Constant yOAMax." annotation(
        Placement(transformation(origin = {94, 32}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Sources.Constant conYMin(k = yOAMin) "Constant yOAMin." annotation(
        Placement(transformation(origin = {94, -16}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Add dYCO2(k1 = +1, k2 = -1) "Damper span: dY = yOAMax - yOAMin." annotation(
        Placement(transformation(origin = {0, 26}, extent = {{10, -10}, {-10, 10}})));
      // Scale normalized demand into damper span: mul = limCO2 * dY
      Modelica.Blocks.Math.Product normCO2 "Product block used to scale normalized CO2 demand with damper range." annotation(
        Placement(transformation(origin = {-26, 58}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Product mulCO2 "Scaled CO2 contribution: mul = (normalized CO2) * (yOAMax - yOAMin)." annotation(
        Placement(transformation(origin = {-96, 32}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
      // Add minimum: yOA = yOAMin + mul
      Modelica.Blocks.Math.Add yDam(k1 = +1, k2 = +1) "Computed OA damper command (before final limiting): yOA = yOAMin + mul." annotation(
        Placement(transformation(origin = {-130, 26}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
      Modelica.Blocks.Nonlinear.Limiter limDam(uMax = 1, uMin = 0) "Final safety limiter to enforce damper command in [0,1]." annotation(
        Placement(transformation(origin = {-164, 26}, extent = {{10, -10}, {-10, 10}})));
      // ---------------------------------------------------------------------------
      // Enable / disable gating
      // ---------------------------------------------------------------------------
      Modelica.Blocks.Logical.Not notWin "notWin = NOT(winOpen). True when windows are closed and HVAC OA control is permitted." annotation(
        Placement(transformation(origin = {112, -92}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Logical.And sysPerm "Enable signal for OA control: andSys = sysOn AND notWin." annotation(
        Placement(transformation(origin = {30, -54}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offDamOA(k = 0) "Damper command when disabled (typically 0)." annotation(
        Placement(transformation(origin = {-164, -90}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Logical.Switch swiDamOA "Output selection: if enabled -> use computed OA damper; else -> use offDamOA." annotation(
        Placement(transformation(origin = {-200, -54}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
    equation
      connect(conYMax.y, dYCO2.u1) annotation(
        Line(points = {{83, 32}, {12, 32}}, color = {0, 0, 127}));
      connect(conYMin.y, dYCO2.u2) annotation(
        Line(points = {{83, -16}, {63, -16}, {63, 20}, {12, 20}}, color = {0, 0, 127}));
      connect(co2Err.y, normCO2.u1) annotation(
        Line(points = {{-15, 134}, {-15, 64}}, color = {0, 0, 127}));
      connect(normCO2.y, limNorCO2.u) annotation(
        Line(points = {{-37, 58}, {-51, 58}}, color = {0, 0, 127}));
      connect(limNorCO2.y, mulCO2.u1) annotation(
        Line(points = {{-73, 58}, {-73, 38}, {-84, 38}}, color = {0, 0, 127}));
      connect(dYCO2.y, mulCO2.u2) annotation(
        Line(points = {{-11, 26}, {-84, 26}}, color = {0, 0, 127}));
      connect(mulCO2.y, yDam.u1) annotation(
        Line(points = {{-107, 32}, {-118, 32}}, color = {0, 0, 127}));
      connect(conYMin.y, yDam.u2) annotation(
        Line(points = {{83, -16}, {-113, -16}, {-113, 20}, {-118, 20}}, color = {0, 0, 127}));
      connect(conCO2Db.y, co2Start.u2) annotation(
        Line(points = {{161, 24}, {152, 24}, {152, 44}}, color = {0, 0, 127}));
      connect(CO2Set, co2Start.u1) annotation(
        Line(points = {{199, 55}, {154, 55}, {154, 56}, {152, 56}}, color = {0, 0, 127}));
      connect(co2Start.y, co2Span.u2) annotation(
        Line(points = {{129, 50}, {106, 50}, {106, 66}}, color = {0, 0, 127}));
      connect(conCO2Max.y, co2Span.u1) annotation(
        Line(points = {{159, 78}, {106, 78}}, color = {0, 0, 127}));
      connect(conOne.y, divCO2.u1) annotation(
        Line(points = {{49, 100}, {38, 100}}, color = {0, 0, 127}));
      connect(co2Span.y, limSpan.u) annotation(
        Line(points = {{84, 72}, {72, 72}}, color = {0, 0, 127}));
      connect(limSpan.y, divCO2.u2) annotation(
        Line(points = {{50, 72}, {38, 72}, {38, 88}}, color = {0, 0, 127}));
      connect(divCO2.y, normCO2.u2) annotation(
        Line(points = {{16, 94}, {6, 94}, {6, 52}, {-14, 52}}, color = {0, 0, 127}));
      connect(yDam.y, limDam.u) annotation(
        Line(points = {{-141, 26}, {-152, 26}}, color = {0, 0, 127}));
      connect(co2Start.y, co2Err.u2) annotation(
        Line(points = {{130, 50}, {116, 50}, {116, 128}, {8, 128}}, color = {0, 0, 127}));
      connect(CO2Meas, co2Err.u1) annotation(
        Line(points = {{200, 140}, {8, 140}}, color = {0, 0, 127}));
      connect(winOpe, notWin.u) annotation(
        Line(points = {{176, -92}, {124, -92}}, color = {255, 0, 255}));
      connect(sysOn, sysPerm.u1) annotation(
        Line(points = {{174, -54}, {42, -54}}, color = {255, 0, 255}));
      connect(notWin.y, sysPerm.u2) annotation(
        Line(points = {{102, -92}, {42, -92}, {42, -62}}, color = {255, 0, 255}));
      connect(limDam.y, swiDamOA.u1) annotation(
        Line(points = {{-174, 26}, {-188, 26}, {-188, -46}}, color = {0, 0, 127}));
      connect(sysPerm.y, swiDamOA.u2) annotation(
        Line(points = {{20, -54}, {-188, -54}}, color = {255, 0, 255}));
      connect(offDamOA.y, swiDamOA.u3) annotation(
        Line(points = {{-176, -90}, {-188, -90}, {-188, -62}}, color = {0, 0, 127}));
      connect(swiDamOA.y, yDamOut) annotation(
        Line(points = {{-210, -54}, {-234, -54}}, color = {0, 0, 127}));
      annotation(
        Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-1, 1}, extent = {{-85, -65}, {85, 65}}, imageSource = "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")}),
        Diagram(coordinateSystem(extent = {{-240, 160}, {220, -120}})));
    end OACtrl;

    model HydronicTSupSetCtrl
      // ---------------------------------------------------------------------------
      // Hydronic supply-air-temperature (SAT) controller
      //
      // What it does:
      // 1) Computes a SAT setpoint (SATSP) from room temperature error (TRoo-TRooSet)
      //    using a linear reset between TSupSetNeu and TSupSetMin with a deadband.
      // 2) Runs a PI loop to track SATSP using the cooling coil valve (yVal).
      // 3) Enables/disables valve and pump based on system enable and window status.
      //
      // Notes:
      // - The valve is forced OFF when the system is not allowed to run.
      // - When enabled, the valve command is at least ValMinOn to avoid “stiction”
      //   and to keep the coil loop responsive at low loads.
      // - Pump is commanded ON whenever the system is enabled and windows are closed.
      // ---------------------------------------------------------------------------
      // Inputs
      Modelica.Blocks.Interfaces.RealInput TRoo "Room/zone air temperature measurement [K]. Used to compute cooling demand (TRoo-TRooSet)." annotation(
        Placement(transformation(origin = {-120, 32}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 6}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet "Room/zone temperature setpoint [K]. Compared with TRoo to determine SAT reset level." annotation(
        Placement(transformation(origin = {-122, -22}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, -58}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSup "Supply air temperature measurement [K] (downstream of coil/supply duct sensor). Controlled variable for the PI loop." annotation(
        Placement(transformation(origin = {-120, -88}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 68}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC allowed to operate). If false, valve and pump are forced OFF." annotation(
        Placement(transformation(origin = {-116, 184}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open / natural ventilation flag (true = window open). If true, valve and pump are forced OFF." annotation(
        Placement(transformation(origin = {-116, 146}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yValChi "Cooling coil valve command (0..1). When enabled, equals max(PI, ValMinOn); when disabled, equals ValOff." annotation(
        Placement(transformation(origin = {314, 168}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 44}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yPumChi "Hydronic pump command (0/1). ON when system is enabled AND windows are closed." annotation(
        Placement(transformation(origin = {314, 224}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -42}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput TSupSet "Calculated supply-air temperature setpoint [K]. Reset from TSupSetNeu toward TSupSetMin as room temperature error increases." annotation(
        Placement(transformation(origin = {312, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -86}, extent = {{-10, -10}, {10, 10}})));
      // Parameters
      parameter Modelica.Units.SI.TemperatureDifference dTDb = 0.2 "SAT reset deadband [K]. No SAT reset until (TRoo-TRooSet) exceeds dTDb, which prevents hunting around setpoint.";
      parameter Modelica.Units.SI.TemperatureDifference dTMax = 2 "Room temperature error [K] that drives SAT fully to TSupSetMin. Larger value makes SAT reset less aggressive.";
      parameter Modelica.Units.SI.Temperature TSupSetNeu = 273.15 + 18 "Neutral SAT [K] used when there is little/no cooling demand (typically warmer to save energy).";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Minimum SAT [K] in cooling. Lower bound of the SAT reset (coldest allowed SATSP).";
      parameter Real kVal = 0.05 "Valve PI proportional gain. Higher kVal increases responsiveness but can increase oscillation.";
      parameter Modelica.Units.SI.Time TiVal = 300 "Valve PI integral time [s]. Smaller TiVal integrates faster (removes offset faster) but may cause instability.";
      // ---------------------------------------------------------------------------
      // Control logic blocks
      // ---------------------------------------------------------------------------
      // Compute room temperature error: e = TRoo - TRooSet
      Modelica.Blocks.Math.Add errTRoo(k1 = +1, k2 = -1) "Room temperature error [K]. Positive means room is warmer than setpoint (cooling demand)." annotation(
        Placement(transformation(origin = {-60, -2}, extent = {{-10, -10}, {10, 10}})));
      // Apply deadband before SAT reset: (e - dTDb)
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conDTDb(k = dTDb) "Deadband constant [K] used to delay SAT reset until cooling demand is meaningful." annotation(
        Placement(transformation(origin = {-60, -38}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Add errDb(k1 = +1, k2 = -1) "Deadbanded error: (TRoo-TRooSet) - dTDb. Negative/near-zero values imply little demand." annotation(
        Placement(transformation(origin = {-16, -8}, extent = {{-10, -10}, {10, 10}})));
      // Normalize demand to a 0..1 reset signal: u = ((e-dTDb)/dTMax), clipped to [0,1]
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conInvDTMax(k = 1/dTMax) "Inverse of dTMax used to normalize room error into a 0..1 reset signal." annotation(
        Placement(transformation(origin = {-16, -58}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Product norm "Normalized reset signal u = ((e - dTDb) * (1/dTMax))." annotation(
        Placement(transformation(origin = {26, -14}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
      Modelica.Blocks.Nonlinear.Limiter limRes(uMax = 1, uMin = 0) "Limiter to keep reset signal within [0,1]. u=0 -> neutral SAT, u=1 -> minimum SAT." annotation(
        Placement(transformation(origin = {64, -14}, extent = {{-10, -10}, {10, 10}})));
      // Build SAT setpoint from neutral and minimum SAT:
      // SATSP = TSupSetNeu + u*(TSupSetMin - TSupSetNeu)
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetMin(k = TSupSetMin) "Minimum SAT constant [K]." annotation(
        Placement(transformation(origin = {24, 82}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetNeu(k = TSupSetNeu) "Neutral SAT constant [K]." annotation(
        Placement(transformation(origin = {26, 40}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dTSupSet(k1 = +1, k2 = -1) "SAT reset span: TSupSetMin - TSupSetNeu (typically negative because TSupSetMin < TSupSetNeu)." annotation(
        Placement(transformation(origin = {68, 56}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Product mul "Scaled reset span: u*(TSupSetMin - TSupSetNeu)." annotation(
        Placement(transformation(origin = {118, 18}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Add TSupSetCal(k1 = +1, k2 = +1) "Computed SAT setpoint: TSupSetNeu + u*(TSupSetMin - TSupSetNeu)." annotation(
        Placement(transformation(origin = {158, 34}, extent = {{-10, -10}, {10, 10}})));
      // PI controller: tracks SATSP by modulating cooling valve
      Buildings.Controls.OBC.CDL.Reals.PID pidVal(controllerType = Buildings.Controls.OBC.CDL.Types.SimpleController.PI, k = kVal, Ti = TiVal, reverseActing = false, yMax = 1, yMin = 0) "PI loop controlling valve (y) to drive measured TSA (u_m) toward SATSP (u_s)." annotation(
        Placement(transformation(origin = {204, 34}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      // System permissive logic:
      // enable = sysOn AND (NOT winOpen)
      Modelica.Blocks.Logical.Not notWinOpe "Logical NOT of winOpen. If winOpen = true, then notWin = false; If winOpen = false, then notWin = true." annotation(
        Placement(transformation(origin = {-56, 146}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And sysPerm "Enable signal: sysOn AND notWin. Used to enable pump and valve operation." annotation(
        Placement(transformation(origin = {12, 168}, extent = {{-10, -10}, {10, 10}})));
      // Valve handling when enabled:
      // yVal_on = max(conPID.y, ValMinOn) to avoid sticking and to ensure some minimum flow
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conValMinOn(k = 0.02) "Minimum valve opening when enabled (0..1). Prevents valve sticking and improves numerical robustness." annotation(
        Placement(transformation(origin = {204, 80}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Max maxVal "Selects the larger of PI output and ValMinOn." annotation(
        Placement(transformation(origin = {244, 58}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conValOff(k = 0.0) "Valve command when disabled (normally 0)." annotation(
        Placement(transformation(origin = {204, 194}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiVal "Valve enable switch: if andSys=true -> output maxVal; else -> ValOff." annotation(
        Placement(transformation(origin = {274, 168}, extent = {{-10, 10}, {10, -10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Conversions.BooleanToReal pumCmd(realTrue = 1.0, realFalse = 0.0) "Converts enable boolean to pump command (1=ON, 0=OFF)." annotation(
        Placement(transformation(origin = {118, 224}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(TRoo, errTRoo.u1) annotation(
        Line(points = {{-120, 32}, {-72, 32}, {-72, 4}}, color = {0, 0, 127}));
      connect(TRooSet, errTRoo.u2) annotation(
        Line(points = {{-122, -22}, {-72, -22}, {-72, -8}}, color = {0, 0, 127}));
      connect(errTRoo.y, errDb.u1) annotation(
        Line(points={{-49,-2},{-28,-2}},      color = {0, 0, 127}));
      connect(conDTDb.y, errDb.u2) annotation(
        Line(points = {{-48, -38}, {-28, -38}, {-28, -14}}, color = {0, 0, 127}));
      connect(errDb.y, norm.u1) annotation(
        Line(points={{-5,-8},{14,-8}},      color = {0, 0, 127}));
      connect(conInvDTMax.y, norm.u2) annotation(
        Line(points = {{-4, -58}, {14, -58}, {14, -20}}, color = {0, 0, 127}));
      connect(norm.y, limRes.u) annotation(
        Line(points={{37,-14},{52,-14}},      color = {0, 0, 127}));
      connect(conTSupSetMin.y, dTSupSet.u1) annotation(
        Line(points = {{36, 82}, {56, 82}, {56, 62}}, color = {0, 0, 127}));
      connect(conTSupSetNeu.y, dTSupSet.u2) annotation(
        Line(points = {{38, 40}, {56, 40}, {56, 50}}, color = {0, 0, 127}));
      connect(limRes.y, mul.u2) annotation(
        Line(points={{75,-14},{106,-14},{106,12}},        color = {0, 0, 127}));
      connect(dTSupSet.y, mul.u1) annotation(
        Line(points={{79,56},{106,56},{106,24}},        color = {0, 0, 127}));
      connect(conTSupSetNeu.y, TSupSetCal.u1) annotation(
        Line(points = {{38, 40}, {146, 40}}, color = {0, 0, 127}));
      connect(mul.y, TSupSetCal.u2) annotation(
        Line(points={{129,18},{146,18},{146,28}},        color = {0, 0, 127}));
      connect(TSup, pidVal.u_m) annotation(
        Line(points = {{-120, -88}, {204, -88}, {204, 22}}, color = {0, 0, 127}));
      connect(TSupSetCal.y, pidVal.u_s) annotation(
        Line(points={{169,34},{192,34}},      color = {0, 0, 127}));
      connect(sysOn, sysPerm.u1) annotation(
        Line(points = {{-116, 184}, {0, 184}, {0, 168}}, color = {255, 0, 255}));
      connect(winOpe, notWinOpe.u) annotation(
        Line(points = {{-116, 146}, {-68, 146}}, color = {255, 0, 255}));
      connect(notWinOpe.y, sysPerm.u2) annotation(
        Line(points={{-45,146},{0,146},{0,160}},        color = {255, 0, 255}));
      connect(pidVal.y, maxVal.u2) annotation(
        Line(points = {{216, 34}, {232, 34}, {232, 52}}, color = {0, 0, 127}));
      connect(conValMinOn.y, maxVal.u1) annotation(
        Line(points = {{216, 80}, {232, 80}, {232, 64}}, color = {0, 0, 127}));
      connect(maxVal.y, swiVal.u1) annotation(
        Line(points={{255,58},{262,58},{262,160}},        color = {0, 0, 127}));
      connect(conValOff.y, swiVal.u3) annotation(
        Line(points = {{216, 194}, {262, 194}, {262, 176}}, color = {0, 0, 127}));
      connect(swiVal.y, yValChi) annotation(
        Line(points={{285,168},{314,168}},      color = {0, 0, 127}));
      connect(sysPerm.y, pumCmd.u) annotation(
        Line(points={{23,168},{106,168},{106,224}},        color = {255, 0, 255}));
      connect(pumCmd.y, yPumChi) annotation(
        Line(points = {{130, 224}, {314, 224}}, color = {0, 0, 127}));
      connect(sysPerm.y, swiVal.u2) annotation(
        Line(points={{23,168},{262,168}},      color = {255, 0, 255}));
      connect(TSupSetCal.y, TSupSet) annotation(
        Line(points={{169,34},{178,34},{178,0},{312,0}},          color = {0, 0, 127}));
      annotation(
        Diagram(coordinateSystem(extent = {{-140, 240}, {320, -120}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {0, 48}, rotation = 180, extent = {{-98, 50}, {98, -50}}, imageSource = "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gs8fMyE0YJrbZ7HzWmFpUGZvwX1V2oilIIT88RJGA1zfjBvSG0uDsfB13FOlAixFYeSPlVAa8DFuUqn0QAivB+tPdz395w9Y6xBK/jgJpwEf4TZnLTuGtblaeQXu46y3s38QFU7+GAmnAfkHcaOzSv+vD1bnYkE/3ME5N+zDaqdw8sdISA04PBO3Omf+xIFYruu+TU1w9XPWejkVIaT88XEBxsvegAuwIp19HXCzKrbX8PB/M7thn7u89j9lZz7WpxNW/tgozhrP0aJirEir0PWZYIVuz2T/85xF/rTXcNWqrsH69ELLHxe9MN5bWPEWVnj9dLeX2/sBp2xuOgI38KP+O64v/SqU/hI3cBFi/njYhvFGlqcWlI/Eim2pBe62ubw7d8beA9pXj+06kPnCnxOe30gNM38sHMN4Cno3Bm9X3l/ILcp8Nyn1r2c0ngwc7tsV1wEbVuI2rkLNHwf3YDzV5HjV2487n2bfU/X2zF7NeoZ+yzXL38etMlnwTIeWuAZ63ccnj+Hmj4HyVZhPnazy/KzwJN6qVsFjZEYvu78hcFbR2Esewe3Su7ngXy6fNFXVzs+7jSHnj4E0L9e++bTyxk+/wduU6pC6fTYXtcUF0llye8ETGd8gennlptFLcKt0GkzDTTMLO794T2HAiqdn+099v8OO/XvxFqXUU7hCFu1b4wpuhtwxcUyny+Ajw56XHdt21c+HYK2b62qnbp5V6Pmlq5/+f+j2tWu347+d0tbPA+wpA10/q02vQbexB0872XWZz8s853l59y9F+PmlW4sRM1uL23uwbT6uEo75y3HPHkSQX7Z/Y8TM/o3be9FmPC4TgtI9Kc/fvYoiv2wenqifcxC39qi35lf2eHfvQtynR5Hkl6y2h5dWlZr5fY51VvkPQ/07sKqG9sUn0eSXzPGRqLtcPgq9c2fGDwdyUTJvMO7Nh4jyyzXY84usIbn0OS/v29twwWB0r4Z78iWy/GK134BJ09vQHrf0q3eGE0U0lZ5cgXvxK7r8Um319OBcuhW30/DqGh9/crO7a4/Ht5EzijC/UJ6+VmMibqXn06M+391x98/pu3F1PVHml2mT66nVlUo24Tba+vwn48k8Xi37T8aPD3yJNL9Ij2b57L7sUdwiJyuOPoh78OfBo6/gmjmJOL9AjyzDzFUtC+JPbYr8lTu/h3vxqqzdVE+nfPoRdX55Vhe7XNirVOfi1VgdhGFPd/gEd5XdGx8sPowrBSH6/OIc6VeE0SsU9TuClcFpuLGdjycEr+35sgWuEBwT+YX5+kAdjF/nwNdYFbTdffvVaoD7RQ1enPePgJ7zuzOTX5TCap9tPvuMuGTzZ9VyPoHfoynH+hffMSDNK8QTrQ8++07j87A+JMbyS5J/5Nutn3++9dsjgT/Tyqqw55E55zeevPydH7009ydPN3/l5i7rtT/l0WYwPxERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER6fh/H7w6my0mDdAAAAAASUVORK5CYII="), Bitmap(origin = {0, -48}, rotation = 180, extent = {{-98, 52}, {98, -52}}, imageSource = "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")}));
    end HydronicTSupSetCtrl;

    model FanCtrl
      // Purpose: generate supply fan speed yFanSA and return fan speed yFanRA based on:
      //    -system enable sysOn
      //    -window status winOpen (if open, fans are forced off)
      //    -cooling demand and cooling effectiveness (using hysteresis)
      //    -SAT reset state (whether TSupSet is near TSupSetMin, using hysteresis)
      //    -proportional fan modulation based on room temperature error
      // Inputs
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC schedule/enable allows operation). If false, both fans are forced OFF (0)." annotation(
        Placement(transformation(origin = {-152, 206}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open flag (true = window open). When true, controller blocks operation by forcing both fans OFF (0)." annotation(
        Placement(transformation(origin = {-152, 168}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.RealInput TRoo "Zone/room air temperature measurement [K]. Used to compute room temperature error TRoo-TRooSet and cooling effectiveness TRoo-TSA." annotation(
        Placement(transformation(origin = {-158, 30}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet "Zone/room temperature setpoint [K]. Used with TRoo to detect cooling demand and scale fan speed." annotation(
        Placement(transformation(origin = {-160, -24}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 28}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSupSet "Supply air temperature setpoint [K]. Compared to TSupSetMin to infer 'cooling mode' (SAT reset near minimum) using hysteresis." annotation(
        Placement(transformation(origin = {-160, -116}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, -80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSup "Measured supply air temperature to zone [K]. Used with TRoo to check cooling effectiveness: (TRoo - TSA)." annotation(
        Placement(transformation(origin = {-158, -80}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, -28}, extent = {{-20, -20}, {20, 20}})));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yFanRet "Return fan speed command (0..1). Equals 0 when system not permissive; otherwise approx yFanSup - dYFanRet, limited to [yFanRetMin, 1]." annotation(
        Placement(transformation(origin = {274, -58}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -30}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanSup "Supply fan speed command (0..1). Equals 0 when system not permissive; otherwise equals modulated or minimum fan command." annotation(
        Placement(transformation(origin = {260, 190}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 32}, extent = {{-10, -10}, {10, 10}})));
      // Parameters
      parameter Modelica.Units.SI.TemperatureDifference eRooMax = 2.5 "Room temp error (TRoo-TRooSet) that drives SA fan command to yFanMax (linear scaling).";
      parameter Modelica.Units.SI.TemperatureDifference epsOn = 0.1 "Enter ‘SAT at minimum’ when (TSupSetMin - TSupSet) >= -epsOn (TSupSet within epsOn above TSupSetMin).";
      parameter Modelica.Units.SI.TemperatureDifference epsOff = 0.5 "Exit ‘SAT at minimum’ when (TSupSetMin - TSupSet) <= -epsOff (TSupSet moved away from TSupSetMin by epsOff).";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOn = 0.2 "Cooling-effective ON threshold: enable when (TRoo - TSA) >= dTSupOn (supply air is sufficiently cooler).";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOff = 0.05 "Cooling-effective OFF threshold: disable when (TRoo - TSA) <= dTSupOff.";
      parameter Modelica.Units.SI.TemperatureDifference eRooOn = 0.3 "Cooling-demand ON threshold: enable when (TRoo - TRooSet) >= eRooOn.";
      parameter Modelica.Units.SI.TemperatureDifference eRooOff = 0.05 "Cooling-demand OFF threshold: disable when (TRoo - TRooSet) <= eRooOff.";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Minimum supply air temperature setpoint during cooling.";
      parameter Real yFanMin = 0.05 "Minimum allowed SA fan speed command (0..1)";
      parameter Real yFanMax = 1.00 "Maximum allowed SA fan speed command (0..1)";
      parameter Real dYFanRet = 0.05 "Return fan offset relative to supply fan: yFanRA = yFanSA - dYFanRet (then limited)";
      parameter Real yFanRetMin = 0.05 "Minimum allowed return fan speed";
      parameter Modelica.Units.SI.TemperatureDifference dTOverCoo = 1 "Exit modulation mode when room is overcooled: TRoo - TRooSet < -dTOverCoo.";
      // control logic overview
      // 1) System permissive condition:
      //    sysPerm = sysOn AND (NOT winOpen)
      //    If not permissive, both fans forced to 0.
      //
      // 2) Compute signals:
      //    errTRoo   = TRoo - TRooSet                (cooling demand indicator)
      //    dTRooTSup   = TRoo - TSA                    (cooling effectiveness indicator)
      //    dTSATmin  = -(TSupSet - TSupSetMin)              (whether SAT reset is near cooling minimum)
      //
      // 3) Hysteresis to avoid chattering:
      //    greTRooHys: coolingDemand  = hysteresis(errTRoo;  uHigh=eRooOn,  uLow=eRooOff)
      //    lesTsaHys: coolingEff      = hysteresis(dTRooTSup;  uHigh=dTSupOn,  uLow=dTSupOff)
      //    satMinHys: satAtMin        = hysteresis(dTSATmin; uLow=epsOn,    uHigh=epsOff)
      //      Note: satAtMin = true means TSupSet is close to TSupSetMin (i.e., cooling mode).
      //
      // 4) Modulation mode latch (prevents low-load oscillation):
      //    Set modulation mode when demAndEff AND satAtMin becomes true.
      //    Reset modulation mode when either:
      //    room is overcooled: (TRoo - TRooSet) < -dTOverCoo, or
      //    system not permissive: NOT(sysPerm).
      //
      // 5) Fan modulation (only meaningful when sysPerm=true):
      //    If modulation mode is active:
      //    yFanSA = yFanMin + clamp((TRoo-TRooSet)/eRooMax, 0..1) * (yFanMax - yFanMin)
      //    If enaFan=false, hold SA fan at yFanMin
      //
      // 6) Final outputs:
      //    yFanSA = sysPerm ? yFanCmd : 0
      //    yFanRA = sysPerm ? clamp(yFanSA - dYFanRet, yFanRetMin..1) : 0
      // Control logic
      Modelica.Blocks.Logical.Not notWin "True when window is NOT open" annotation(
        Placement(transformation(origin = {-92, 168}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And sysPerm "System permissive: sysOn AND notWin" annotation(
        Placement(transformation(origin = {-24, 190}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add errTRoo(k1 = +1, k2 = -1) "e=TRoo - TRooSet" annotation(
        Placement(transformation(origin = {-98, -4}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dTRooTSup(k1 = +1, k2 = -1) "dT = Troom - TSA" annotation(
        Placement(transformation(origin = {-98, -60}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Hysteresis hysDem(uHigh = eRooOn, uLow = eRooOff) "Cooling demand flag with hysteresis based on TRoo-TRooSet" annotation(
        Placement(transformation(origin = {-58, -4}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Hysteresis hysCooEffSup(uHigh = dTSupOn, uLow = dTSupOff) "Cooling effectiveness flag with hysteresis based on TRoo-TSA" annotation(
        Placement(transformation(origin = {-58, -60}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetMin(k = TSupSetMin) annotation(
        Placement(transformation(origin = {-150, -152}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dTSupSetMin(k1 = -1, k2 = +1) "TSupSetMin - TSupSet" annotation(
        Placement(transformation(origin = {-100, -122}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Hysteresis hysTSupSetMin(uHigh = -epsOn, uLow = -epsOff) "True when TSupSet is close to TSupSetMin" annotation(
        Placement(transformation(origin = {-56, -122}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And andDemEff "coolingDemand AND coolingEff" annotation(
        Placement(transformation(origin = {-18, -30}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conInvERooMax(k = 1/eRooMax) annotation(
        Placement(transformation(origin = {-100, 54}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Product normTRooErr "Normalize errTRoo by eRooMax: err*(1/eRooMax)" annotation(
        Placement(transformation(origin = {-44, 48}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Nonlinear.Limiter limNorErr(uMax = 1, uMin = 0) "Clamp normalized error to 0..1" annotation(
        Placement(transformation(origin = {4, 48}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
      Modelica.Blocks.Math.Product mulY annotation(
        Placement(transformation(origin = {62, 54}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conYFanMax(k = yFanMax) annotation(
        Placement(transformation(origin = {-46, 140}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conYFanMin(k = yFanMin) annotation(
        Placement(transformation(origin = {-44, 94}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dYFan(k1 = +1, k2 = -1) annotation(
        Placement(transformation(origin = {4, 116}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Add yFanMod(k1 = +1, k2 = +1) "yMin + mulY" annotation(
        Placement(transformation(origin = {94, 88}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiFanMod "If enaFan then yFanMod else yFanMin" annotation(
        Placement(transformation(origin = {130, 34}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Logical.Switch swiFanSup "If sysPerm then yFanCmd else 0" annotation(
        Placement(transformation(origin = {170, 190}, extent = {{-10, 10}, {10, -10}}, rotation = -0)));
      Modelica.Blocks.Sources.Constant conDYFanRet(k = dYFanRet) annotation(
        Placement(transformation(origin = {136, -134}, extent = {{10, 10}, {-10, -10}}, rotation = -180)));
      Modelica.Blocks.Math.Add subFanRet(k1 = +1, k2 = -1) "Compute yFanSA - dYFanRet" annotation(
        Placement(transformation(origin = {162, -94}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiFanRet "If sysPerm then limited RA command else 0" annotation(
        Placement(transformation(origin = {232, -58}, extent = {{-10, 10}, {10, -10}})));
      Modelica.Blocks.Nonlinear.Limiter limFanRet(uMax = 1, uMin = yFanRetMin) "Limit return fan command to [yFanRetMin, 1]" annotation(
        Placement(transformation(origin = {200, -94}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conFanOff(k = 0.0) annotation(
        Placement(transformation(origin = {132, 224}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Logical.TrueFalseHold truFalHol(trueHoldDuration = 600, falseHoldDuration = 300) annotation(
        Placement(transformation(origin = {80, -74}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.RSFlipFlop modLat "Latch for fan modulation mode: set when demand+effect and SAT-at-min; reset when overcooled or sysPerm=false." annotation(
        Placement(transformation(origin = {46, -80}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.LessThreshold rooBelowSp(threshold = -dTOverCoo) "True when (TRoo - TRooSet) < -dTOverCoo" annotation(
        Placement(transformation(origin = {-56, -168}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Not notSysPerm annotation(
        Placement(transformation(origin = {-56, -210}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Or rstMod "Reset latch if overcooled OR sysPerm=false" annotation(
        Placement(transformation(origin = {6, -170}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And setMod "Set latch when demand&eff and SAT at min" annotation(
        Placement(transformation(origin = {12, -74}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(sysOn, sysPerm.u1) annotation(
        Line(points = {{-152, 206}, {-36, 206}, {-36, 190}}, color = {255, 0, 255}));
      connect(winOpe, notWin.u) annotation(
        Line(points = {{-152, 168}, {-104, 168}}, color = {255, 0, 255}));
      connect(notWin.y, sysPerm.u2) annotation(
        Line(points = {{-81, 168}, {-37, 168}, {-37, 182}}, color = {255, 0, 255}));
      connect(TRoo, errTRoo.u1) annotation(
        Line(points = {{-158, 30}, {-110, 30}, {-110, 2}}, color = {0, 0, 127}));
      connect(TRooSet, errTRoo.u2) annotation(
        Line(points = {{-160, -24}, {-110, -24}, {-110, -10}}, color = {0, 0, 127}));
      connect(TRoo, dTRooTSup.u1) annotation(
        Line(points = {{-158, 30}, {-124, 30}, {-124, -54}, {-110, -54}}, color = {0, 0, 127}));
      connect(TSup, dTRooTSup.u2) annotation(
        Line(points = {{-158, -80}, {-110, -80}, {-110, -66}}, color = {0, 0, 127}));
      connect(dTRooTSup.y, hysCooEffSup.u) annotation(
        Line(points = {{-86, -60}, {-70, -60}}, color = {0, 0, 127}));
      connect(errTRoo.y, hysDem.u) annotation(
        Line(points = {{-86, -4}, {-70, -4}}, color = {0, 0, 127}));
      connect(TSupSet, dTSupSetMin.u1) annotation(
        Line(points = {{-160, -116}, {-112, -116}}, color = {0, 0, 127}));
      connect(conTSupSetMin.y, dTSupSetMin.u2) annotation(
        Line(points = {{-138, -152}, {-112, -152}, {-112, -128}}, color = {0, 0, 127}));
      connect(dTSupSetMin.y, hysTSupSetMin.u) annotation(
        Line(points = {{-88, -122}, {-68, -122}}, color = {0, 0, 127}));
      connect(errTRoo.y, normTRooErr.u2) annotation(
        Line(points = {{-86, -4}, {-78, -4}, {-78, 42}, {-56, 42}}, color = {0, 0, 127}));
      connect(conInvERooMax.y, normTRooErr.u1) annotation(
        Line(points = {{-88, 54}, {-56, 54}}, color = {0, 0, 127}));
      connect(normTRooErr.y, limNorErr.u) annotation(
        Line(points = {{-32, 48}, {-8, 48}}, color = {0, 0, 127}));
      connect(conYFanMin.y, dYFan.u2) annotation(
        Line(points = {{-32, 94}, {-8, 94}, {-8, 110}}, color = {0, 0, 127}));
      connect(limNorErr.y, mulY.u2) annotation(
        Line(points = {{16, 48}, {50, 48}}, color = {0, 0, 127}));
      connect(dYFan.y, mulY.u1) annotation(
        Line(points = {{16, 116}, {50, 116}, {50, 60}}, color = {0, 0, 127}));
      connect(conYFanMin.y, yFanMod.u1) annotation(
        Line(points = {{-32, 94}, {82, 94}}, color = {0, 0, 127}));
      connect(mulY.y, yFanMod.u2) annotation(
        Line(points = {{73, 54}, {79, 54}, {79, 82}, {82, 82}}, color = {0, 0, 127}));
      connect(yFanMod.y, swiFanMod.u1) annotation(
        Line(points = {{106, 88}, {118, 88}, {118, 42}}, color = {0, 0, 127}));
      connect(conYFanMin.y, swiFanMod.u3) annotation(
        Line(points = {{-32, 94}, {-20, 94}, {-20, 26}, {118, 26}}, color = {0, 0, 127}));
      connect(sysPerm.y, swiFanSup.u2) annotation(
        Line(points = {{-12, 190}, {158, 190}}, color = {255, 0, 255}));
      connect(swiFanMod.y, swiFanSup.u1) annotation(
        Line(points = {{142, 34}, {158, 34}, {158, 182}}, color = {0, 0, 127}));
      connect(conFanOff.y, swiFanSup.u3) annotation(
        Line(points = {{144, 224}, {158, 224}, {158, 198}}, color = {0, 0, 127}));
      connect(swiFanSup.y, yFanSup) annotation(
        Line(points = {{182, 190}, {260, 190}}, color = {0, 0, 127}));
      connect(conDYFanRet.y, subFanRet.u2) annotation(
        Line(points = {{148, -134}, {150, -134}, {150, -100}}, color = {0, 0, 127}));
      connect(conFanOff.y, swiFanRet.u3) annotation(
        Line(points = {{144, 224}, {220, 224}, {220, -50}}, color = {0, 0, 127}));
      connect(sysPerm.y, swiFanRet.u2) annotation(
        Line(points = {{-12, 190}, {132, 190}, {132, 134}, {180, 134}, {180, -58}, {220, -58}}, color = {255, 0, 255}));
      connect(subFanRet.y, limFanRet.u) annotation(
        Line(points = {{174, -94}, {188, -94}}, color = {0, 0, 127}));
      connect(limFanRet.y, swiFanRet.u1) annotation(
        Line(points = {{212, -94}, {220, -94}, {220, -66}}, color = {0, 0, 127}));
      connect(swiFanRet.y, yFanRet) annotation(
        Line(points = {{244, -58}, {274, -58}}, color = {0, 0, 127}));
      connect(hysDem.y, andDemEff.u1) annotation(
        Line(points = {{-46, -4}, {-30, -4}, {-30, -30}}, color = {255, 0, 255}));
      connect(hysCooEffSup.y, andDemEff.u2) annotation(
        Line(points = {{-46, -60}, {-30, -60}, {-30, -38}}, color = {255, 0, 255}));
      connect(swiFanSup.y, subFanRet.u1) annotation(
        Line(points = {{182, 190}, {196, 190}, {196, -22}, {150, -22}, {150, -88}}, color = {0, 0, 127}));
      connect(truFalHol.y, swiFanMod.u2) annotation(
        Line(points = {{92, -74}, {94, -74}, {94, 34}, {118, 34}}, color = {255, 0, 255}));
      connect(errTRoo.y, rooBelowSp.u) annotation(
        Line(points = {{-86, -4}, {-78, -4}, {-78, -168}, {-68, -168}}, color = {0, 0, 127}));
      connect(sysPerm.y, notSysPerm.u) annotation(
        Line(points = {{-12, 190}, {4, 190}, {4, 226}, {-186, 226}, {-186, -210}, {-68, -210}}, color = {255, 0, 255}));
      connect(rooBelowSp.y, rstMod.u1) annotation(
        Line(points = {{-45, -168}, {-45, -170}, {-6, -170}}, color = {255, 0, 255}));
      connect(notSysPerm.y, rstMod.u2) annotation(
        Line(points = {{-45, -210}, {-45, -178}, {-6, -178}}, color = {255, 0, 255}));
      connect(rstMod.y, modLat.R) annotation(
        Line(points = {{17, -170}, {24, -170}, {24, -86}, {34, -86}}, color = {255, 0, 255}));
      connect(andDemEff.y, setMod.u1) annotation(
        Line(points = {{-7, -30}, {0, -30}, {0, -74}}, color = {255, 0, 255}));
      connect(setMod.y, modLat.S) annotation(
        Line(points = {{23, -74}, {34, -74}}, color = {255, 0, 255}));
      connect(modLat.Q, truFalHol.u) annotation(
        Line(points = {{57, -74}, {68, -74}}, color = {255, 0, 255}));
      connect(conYFanMax.y, dYFan.u1) annotation(
        Line(points = {{-34, 140}, {-8, 140}, {-8, 122}}, color = {0, 0, 127}));
      connect(hysTSupSetMin.y, setMod.u2) annotation(
        Line(points = {{-44, -122}, {0, -122}, {0, -82}}, color = {255, 0, 255}));
      annotation(
        Diagram(coordinateSystem(extent = {{-200, 240}, {280, -220}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-1, -5}, extent = {{-83, -75}, {83, 75}}, imageSource = "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")}));
    end FanCtrl;

    model Controller
      // Inputs
      Modelica.Blocks.Interfaces.RealInput TRoo annotation(
        Placement(transformation(origin = {-122, 30}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 40}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet annotation(
        Placement(transformation(origin = {-120, -36}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 0}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSup annotation(
        Placement(transformation(origin = {-120, 88}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput CO2Set annotation(
        Placement(transformation(origin = {-125, -181}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, -80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput CO2Meas annotation(
        Placement(transformation(origin = {-125, -217}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, -40}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn annotation(
        Placement(transformation(origin = {-124, -102}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe annotation(
        Placement(transformation(origin = {-124, -138}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yValChi annotation(
        Placement(transformation(origin = {252, 76}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 46}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yPumChi annotation(
        Placement(transformation(origin = {250, 42}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 82}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanSup annotation(
        Placement(transformation(origin = {248, -36}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -10}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanRet annotation(
        Placement(transformation(origin = {248, -64}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -44}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yDamOut annotation(
        Placement(transformation(origin = {252, -200}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -82}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      // Parameters
      // ---- SAT / hydronic loop tuning ----
      parameter Modelica.Units.SI.TemperatureDifference dTDb = 0.2 "SAT reset deadband (K)";
      parameter Modelica.Units.SI.TemperatureDifference dTMax = 2 "Room error that drives SAT to TSupSetMin (K)";
      parameter Modelica.Units.SI.Temperature TSupSetNeu = 273.15 + 18 "Neutral SAT setpoint when no cooling demand (K)";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Minimum cooling SAT setpoint (K)";
      parameter Real kVal = 0.05 "PI proportional gain for valve loop";
      parameter Modelica.Units.SI.Time TiVal = 300 "PI integral time for valve loop (s)";
      // ---- Fan loop tuning ----
      parameter Modelica.Units.SI.TemperatureDifference eRooOn = 0.3 "Enable cooling demand when TRoo-TRooSet >= eRooOn (K)";
      parameter Modelica.Units.SI.TemperatureDifference eRooOff = 0.05 "Disable cooling demand when TRoo-TRooSet <= eRooOff (K)";
      parameter Modelica.Units.SI.TemperatureDifference eRooMax = 2.5 "Room error (K) that drives SA fan to max";
      parameter Modelica.Units.SI.TemperatureDifference epsOn = 0.1 "Fan enabled when SATSP-TSupSetMin <= epsOn (K)";
      parameter Modelica.Units.SI.TemperatureDifference epsOff = 0.5 "Fan disabled when SATSP-TSupSetMin >= epsOff (K)";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOn = 0.2 "Cooling-effective when TRoo-TSA >= dTSupOn (K)";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOff = 0.05 "Not cooling-effective when TRoo-TSA <= dTSupOff (K)";
      parameter Real yFanMin = 0.05 "Minimum fan speed (0..1)";
      parameter Real yFanMax = 1.00 "Maximum fan speed (0..1)";
      parameter Real dYFanRet = 0.05 "Return fan offset (Ret = Sup - dYFanRet)";
      parameter Real yFanRetMin = 0.05 "Minimum return air fan speed (0..1)";
      // ---- OA / CO2 loop tuning ----
      parameter Real CO2Max_ppm = 1000 "CO2 where OA hits maximum (ppm)";
      parameter Real CO2Db_ppm = 20 "CO2 deadband shift (ppm): ramp starts at CO2SetIn + CO2Db_ppm";
      parameter Real yOutMin = 0.10 "Minimum outdoor air damper command (0..1)";
      parameter Real yOutMax = 1.00 "Maximum outdoor air damper command (0..1)";
      // Sub-controllers
      //
      //
      FanCtrl fanCtrl(eRooMax = eRooMax, epsOn = epsOn, epsOff = epsOff, dTSupOn = dTSupOn, dTSupOff = dTSupOff, eRooOn = eRooOn, eRooOff = eRooOff, TSupSetMin = TSupSetMin,  // keep consistent with SAT controller
      yFanMin = yFanMin, yFanMax = yFanMax, dYFanRet = dYFanRet, yFanRetMin = yFanRetMin) annotation(
        Placement(transformation(origin = {144, -50}, extent = {{-44, -44}, {44, 44}})));
      //
      OACtrl oaCtrl(CO2Max_ppm = CO2Max_ppm, yOAMin = yOutMin, yOAMax = yOutMax, CO2Db_ppm = CO2Db_ppm) annotation(
        Placement(transformation(origin = {21, -201}, extent = {{33, 33}, {-33, -33}})));
      HydronicTSupSetCtrl hydronicTSupSetCtrl annotation(
        Placement(transformation(origin = {9, 59}, extent = {{-41, -41}, {41, 41}})));
    equation
      connect(TRoo, fanCtrl.TRoo) annotation(
        Line(points = {{-122, 30}, {-80, 30}, {-80, -14}, {92, -14}}, color = {0, 0, 127}));
      connect(TRooSet, fanCtrl.TRooSet) annotation(
        Line(points = {{-120, -36}, {92, -36}, {92, -38}}, color = {0, 0, 127}));
      connect(TSup, fanCtrl.TSup) annotation(
        Line(points = {{-120, 88}, {-92, 88}, {-92, -62}, {92, -62}}, color = {0, 0, 127}));
      connect(CO2Set, oaCtrl.CO2Set) annotation(
        Line(points = {{-124, -180}, {-18, -180}, {-18, -182}}, color = {0, 0, 127}));
      connect(CO2Meas, oaCtrl.CO2Meas) annotation(
        Line(points = {{-124, -216}, {-18, -216}, {-18, -218}}, color = {0, 0, 127}));
      connect(sysOn, fanCtrl.sysOn) annotation(
        Line(points = {{-124, -102}, {108, -102}}, color = {255, 0, 255}));
      connect(sysOn, oaCtrl.sysOn) annotation(
        Line(points = {{-124, -102}, {48, -102}, {48, -162}}, color = {255, 0, 255}));
      connect(winOpe, fanCtrl.winOpe) annotation(
        Line(points = {{-124, -138}, {130, -138}, {130, -102}}, color = {255, 0, 255}));
      connect(winOpe, oaCtrl.winOpe) annotation(
        Line(points = {{-124, -138}, {32, -138}, {32, -162}}, color = {255, 0, 255}));
      connect(fanCtrl.yFanSup, yFanSup) annotation(
        Line(points = {{192, -36}, {248, -36}}, color = {0, 0, 127}));
      connect(fanCtrl.yFanRet, yFanRet) annotation(
        Line(points = {{192, -64}, {248, -64}}, color = {0, 0, 127}));
      connect(oaCtrl.yDamOut, yDamOut) annotation(
        Line(points = {{58, -200}, {252, -200}}, color = {0, 0, 127}));
      connect(TSup, hydronicTSupSetCtrl.TSup) annotation(
        Line(points = {{-120, 88}, {-83, 88}, {-83, 87}, {-40, 87}}, color = {0, 0, 127}));
      connect(TRoo, hydronicTSupSetCtrl.TRoo) annotation(
        Line(points = {{-122, 30}, {-80, 30}, {-80, 62}, {-40, 62}}, color = {0, 0, 127}));
      connect(TRooSet, hydronicTSupSetCtrl.TRooSet) annotation(
        Line(points = {{-120, -36}, {-40, -36}, {-40, 36}}, color = {0, 0, 127}));
      connect(hydronicTSupSetCtrl.yValChi, yValChi) annotation(
        Line(points = {{54, 78}, {150, 78}, {150, 76}, {252, 76}}, color = {0, 0, 127}));
      connect(hydronicTSupSetCtrl.yPumChi, yPumChi) annotation(
        Line(points = {{54, 42}, {250, 42}}, color = {0, 0, 127}));
      connect(hydronicTSupSetCtrl.TSupSet, fanCtrl.TSupSet) annotation(
        Line(points = {{54, 24}, {68, 24}, {68, -86}, {92, -86}}, color = {0, 0, 127}));
      connect(sysOn, hydronicTSupSetCtrl.sysOn) annotation(
        Line(points = {{-124, -102}, {-24, -102}, {-24, 10}}, color = {255, 0, 255}));
      connect(winOpe, hydronicTSupSetCtrl.winOpe) annotation(
        Line(points = {{-124, -138}, {-4, -138}, {-4, 10}}, color = {255, 0, 255}));
      annotation(
        Diagram(coordinateSystem(extent = {{-140, 120}, {260, -260}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-1, 9}, extent = {{-87, 63}, {87, -63}}, imageSource = "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")}));
    end Controller;

    model ActuatorEnable
      parameter Real dFanOff = 0.05 "RA fan offset (RA = SA - dFan)";
      parameter Real yFanRetMin = 0.07 "Minimum RA fan speed";
      // inputs
      //outputs
      Modelica.Blocks.Interfaces.RealOutput yFanRet annotation(
        Placement(transformation(origin = {-322, -138}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {110, -68}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanSup annotation(
        Placement(transformation(origin = {-324, -44}, extent = {{10, -10}, {-10, 10}}, rotation = -0), iconTransformation(origin = {110, -32}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yValChi annotation(
        Placement(transformation(origin = {-324, 28}, extent = {{10, -10}, {-10, 10}}, rotation = -0), iconTransformation(origin = {110, 36}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yPumChi annotation(
        Placement(transformation(origin = {-324, 104}, extent = {{10, -10}, {-10, 10}}, rotation = -0), iconTransformation(origin = {110, 70}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yDamOut annotation(
        Placement(transformation(origin = {-326, 182}, extent = {{10, -10}, {-10, 10}}, rotation = -0), iconTransformation(origin = {110, 2}, extent = {{-10, -10}, {10, 10}})));
      // off signals
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offDamOut(k = 0) annotation(
        Placement(transformation(origin = {-90, 152}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offPumChi(k = 0) annotation(
        Placement(transformation(origin = {-86, 78}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offValChi(k = 0) annotation(
        Placement(transformation(origin = {-88, 2}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offFanSup(k=0.03)
                                                                         annotation(
        Placement(transformation(origin = {-88, -70}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offFanRet(k=0.03)
                                                                         annotation(
        Placement(transformation(origin = {-90, -168}, extent = {{10, -10}, {-10, 10}})));
      // switch logics
      Modelica.Blocks.Logical.Not notWin annotation(
        Placement(transformation(origin = {52, 20}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Logical.And sysOnAndWinClo annotation(
        Placement(transformation(origin = {6, 44}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Logical.Switch swiDamOut annotation(
        Placement(transformation(origin = {-142, 182}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Interfaces.RealInput uDamOut annotation(
        Placement(transformation(origin = {162, 204}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, -84}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Logical.Switch swiPumChi annotation(
        Placement(transformation(origin = {-140, 104}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Interfaces.RealInput uPumChi annotation(
        Placement(transformation(origin = {164, 126}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-122, 78}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Logical.Switch swiValChi annotation(
        Placement(transformation(origin = {-138, 28}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Interfaces.RealInput uValChi annotation(
        Placement(transformation(origin = {164, 92}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 22}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Logical.Switch swiFanSup annotation(
        Placement(transformation(origin = {-136, -44}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Interfaces.RealInput uFanSup annotation(
        Placement(transformation(origin = {166, -24}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, -34}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Logical.Switch swiFanRet annotation(
        Placement(transformation(origin = {-134, -138}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Sources.Constant conDFanOff(k = dFanOff) annotation(
        Placement(transformation(origin = {-268, -104}, extent = {{10, 10}, {-10, -10}}, rotation = -180)));
      Modelica.Blocks.Math.Add subFanRet(k1 = +1, k2 = -1) annotation(
        Placement(transformation(origin = {-224, -98}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Nonlinear.Limiter limFanRet(uMax = 1, uMin = yFanRetMin) annotation(
        Placement(transformation(origin = {-182, -98}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.BooleanInput uSysOn annotation (Placement(
            transformation(
            extent={{20,-20},{-20,20}},
            rotation=-90,
            origin={-62,-120}), iconTransformation(
            extent={{20,-20},{-20,20}},
            rotation=-90,
            origin={-62,-120})));
      Modelica.Blocks.Interfaces.BooleanInput uWinOpe annotation (Placement(
            transformation(extent={{184,-2},{144,38}}), iconTransformation(
            extent={{20,-20},{-20,20}},
            rotation=-90,
            origin={-14,-120})));
    equation
      connect(notWin.y, sysOnAndWinClo.u2) annotation(
        Line(points={{41,20},{18,20},{18,36}},        color = {255, 0, 255}));
      connect(uDamOut, swiDamOut.u1) annotation(
        Line(points = {{162, 204}, {-128, 204}, {-128, 190}, {-130, 190}}, color = {0, 0, 127}));
      connect(offDamOut.y, swiDamOut.u3) annotation(
        Line(points = {{-102, 152}, {-130, 152}, {-130, 174}}, color = {0, 0, 127}));
      connect(sysOnAndWinClo.y, swiDamOut.u2) annotation(
        Line(points={{-5,44},{-26,44},{-26,182},{-130,182}},          color = {255, 0, 255}));
      connect(uPumChi, swiPumChi.u1) annotation(
        Line(points = {{164, 126}, {-126, 126}, {-126, 112}, {-128, 112}}, color = {0, 0, 127}));
      connect(offPumChi.y, swiPumChi.u3) annotation(
        Line(points = {{-98, 78}, {-128, 78}, {-128, 96}}, color = {0, 0, 127}));
      connect(sysOnAndWinClo.y, swiPumChi.u2) annotation(
        Line(points={{-5,44},{-26,44},{-26,104},{-128,104}},          color = {255, 0, 255}));
      connect(offValChi.y, swiValChi.u3) annotation(
        Line(points = {{-100, 2}, {-126, 2}, {-126, 20}}, color = {0, 0, 127}));
      connect(sysOnAndWinClo.y, swiValChi.u2) annotation(
        Line(points={{-5,44},{-26,44},{-26,28},{-126,28}},          color = {255, 0, 255}));
      connect(uFanSup, swiFanSup.u1) annotation(
        Line(points = {{166, -24}, {-122, -24}, {-122, -36}, {-124, -36}}, color = {0, 0, 127}));
      connect(offFanSup.y, swiFanSup.u3) annotation(
        Line(points = {{-100, -70}, {-124, -70}, {-124, -52}}, color = {0, 0, 127}));
      connect(swiFanSup.y, subFanRet.u1) annotation(
        Line(points={{-147,-44},{-236,-44},{-236,-92}},        color = {0, 0, 127}));
      connect(conDFanOff.y, subFanRet.u2) annotation(
        Line(points = {{-257, -104}, {-236, -104}}, color = {0, 0, 127}));
      connect(subFanRet.y, limFanRet.u) annotation(
        Line(points={{-213,-98},{-194,-98}},      color = {0, 0, 127}));
      connect(limFanRet.y, swiFanRet.u1) annotation(
        Line(points={{-171,-98},{-122,-98},{-122,-130}},        color = {0, 0, 127}));
      connect(offFanRet.y, swiFanRet.u3) annotation(
        Line(points = {{-102, -168}, {-122, -168}, {-122, -146}}, color = {0, 0, 127}));
      connect(sysOnAndWinClo.y, swiFanSup.u2) annotation(
        Line(points={{-5,44},{-26,44},{-26,-44},{-124,-44}},          color = {255, 0, 255}));
      connect(sysOnAndWinClo.y, swiFanRet.u2) annotation(
        Line(points={{-5,44},{-26,44},{-26,-138},{-122,-138}},          color = {255, 0, 255}));
      connect(swiFanRet.y, yFanRet) annotation(
        Line(points={{-145,-138},{-322,-138}},      color = {0, 0, 127}));
      connect(swiFanSup.y, yFanSup) annotation(
        Line(points={{-147,-44},{-324,-44}},      color = {0, 0, 127}));
      connect(swiValChi.y, yValChi) annotation(
        Line(points={{-149,28},{-324,28}},      color = {0, 0, 127}));
      connect(swiPumChi.y, yPumChi) annotation(
        Line(points={{-151,104},{-324,104}},      color = {0, 0, 127}));
      connect(swiDamOut.y, yDamOut) annotation(
        Line(points={{-153,182},{-326,182}},      color = {0, 0, 127}));
      connect(uValChi, swiValChi.u1) annotation(
        Line(points = {{164, 92}, {-54, 92}, {-54, 36}, {-126, 36}}, color = {0, 0, 127}));
      connect(uSysOn, sysOnAndWinClo.u1) annotation (Line(points={{-62,-120},{
              26,-120},{26,44},{18,44}}, color={255,0,255}));
      connect(uWinOpe, notWin.u) annotation (Line(points={{164,18},{72,18},{72,
              20},{64,20}}, color={255,0,255}));
      annotation(
        Diagram(coordinateSystem(extent = {{-340, 220}, {180, -180}})),
        Icon(graphics = {Bitmap(origin = {-1, 2}, extent = {{-89, 68}, {89, -68}}, imageSource = "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"), Rectangle(extent = {{-100, 100}, {100, -100}})}));
    end ActuatorEnable;

    model IdealASHPCooPower
      parameter Modelica.Units.SI.SpecificHeatCapacity cpWat = 4180 "Water cp (J/kg.K)";
      parameter Real COPCoo = 2.5 "Assumed COP of ASHP";
      Modelica.Blocks.Math.Add dTWat(k1 = -1, k2 = +1) "Tret - Tsup" annotation(
        Placement(transformation(origin = {56, 30}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Gain cpGain(k = cpWat) annotation(
        Placement(transformation(origin = {12, 30}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Product mCpDT annotation(
        Placement(transformation(origin = {-32, 24}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conZer(k = 0) annotation(
        Placement(transformation(origin = {-32, 72}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Max qCoo annotation(
        Placement(transformation(origin = {-76, 30}, extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conCOP(k = COPCoo) annotation(
        Placement(transformation(origin = {-76, -8}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Division divCOP annotation(
        Placement(transformation(origin = {-118, 24}, extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Interfaces.RealInput TWatRet "CHW return temp (K)" annotation(
        Placement(transformation(origin = {108, 6}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 0}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TWatSup "CHW supply temp (K)" annotation(
        Placement(transformation(origin = {108, 42}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 68}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput mChiWat "Water mass flow (kg/s)" annotation(
        Placement(transformation(origin = {108, -34}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, -68}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealOutput P "ASHP electric power (W)" annotation(
        Placement(transformation(origin = {-148, 24}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(dTWat.y, cpGain.u) annotation(
        Line(points = {{45, 30}, {24, 30}}, color = {0, 0, 127}));
      connect(cpGain.y, mCpDT.u1) annotation(
        Line(points = {{2, 30}, {-20, 30}}, color = {0, 0, 127}));
      connect(conZer.y, qCoo.u1) annotation(
        Line(points = {{-44, 72}, {-64, 72}, {-64, 36}}, color = {0, 0, 127}));
      connect(mCpDT.y, qCoo.u2) annotation(
        Line(points = {{-42, 24}, {-64, 24}}, color = {0, 0, 127}));
      connect(qCoo.y, divCOP.u1) annotation(
        Line(points = {{-86, 30}, {-106, 30}}, color = {0, 0, 127}));
      connect(conCOP.y, divCOP.u2) annotation(
        Line(points = {{-88, -8}, {-106, -8}, {-106, 18}}, color = {0, 0, 127}));
      connect(TWatSup, dTWat.u1) annotation(
        Line(points = {{108, 42}, {68, 42}, {68, 36}}, color = {0, 0, 127}));
      connect(TWatRet, dTWat.u2) annotation(
        Line(points = {{108, 6}, {68, 6}, {68, 24}}, color = {0, 0, 127}));
      connect(mChiWat, mCpDT.u2) annotation(
        Line(points = {{108, -34}, {-20, -34}, {-20, 18}}, color = {0, 0, 127}));
      connect(divCOP.y, P) annotation(
        Line(points = {{-128, 24}, {-148, 24}}, color = {0, 0, 127}));
      annotation(
        Diagram(coordinateSystem(extent = {{-160, 100}, {140, -60}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-4, -2}, extent = {{72, -66}, {-72, 66}}, imageSource = "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")}));
    end IdealASHPCooPower;

    model FanPICtrl

      // ---------------------------------------------------------------------------
      // Supply/return fan controller
      //
      // Control concept:
      // 1) The controller first checks whether second-stage fan cooling should start.
      //    Fan-stage entry requires:
      //      - system permissive (sysOn AND window closed),
      //      - room cooling demand,
      //      - supply air cooler than room,
      //      - supply-air-temperature setpoint near TSupSetMin,
      //      - room not overcooled.
      //
      // 2) Once these entry conditions are satisfied, the controller latches
      //    fanStage = true. The stage remains active until the system is no longer
      //    permissive.
      //
      // 3) While fanStage is false:
      //      - supply fan command = yFanMin
      //      - return fan command follows supply fan with offset dYFanRet
      //
      // 4) While fanStage is true:
      //      - a PI controller modulates supply fan speed between yFanMin and yFanMax
      //        using room temperature relative to room setpoint
      //      - return fan command follows supply fan with offset dYFanRet
      //
      // Notes:
      // - Fan stage is latched with TrueFalseHold to avoid chattering during entry.
      // - Overcool logic is used only to block stage entry, not to reset the stage.
      // - If system is not permissive, both fans are forced OFF.
      // ---------------------------------------------------------------------------

      // Inputs
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC schedule/enable allows operation). If false, both fans are forced OFF (0)." annotation(
        Placement(transformation(origin = {-152, 206}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-102,
                -272},                                                                                                            extent={{-30,-30},
                {30,30}},                                                                                                                                          rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open flag (true = window open). When true, controller blocks operation by forcing both fans OFF (0)." annotation(
        Placement(transformation(origin = {-152, 168}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-6,-270},     extent={{-30,30},
                {30,-30}},                                                                                                                                         rotation = 90)));
      Modelica.Blocks.Interfaces.RealInput TRoo "Zone/room air temperature measurement [K]. Used to compute room temperature error TRoo-TRooSet and cooling effectiveness TRoo-TSA." annotation(
        Placement(transformation(origin={-196,16},    extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-229,189},   extent={{-29,-29},
                {29,29}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet "Zone/room temperature setpoint [K]. Used with TRoo to detect cooling demand and scale fan speed." annotation(
        Placement(transformation(origin={-198,-20},    extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-229,89},    extent={{-29,-29},
                {29,29}})));
      Modelica.Blocks.Interfaces.RealInput TSupSet "Supply air temperature setpoint [K]. Compared to TSupSetMin to infer 'cooling mode' (SAT reset near minimum) using hysteresis." annotation(
        Placement(transformation(origin = {-160, -116}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-230,
                -106},                                                                                                             extent={{-28,-28},
                {28,28}})));
      Modelica.Blocks.Interfaces.RealInput TSup "Measured supply air temperature to zone [K]. Used with TRoo to check cooling effectiveness: (TRoo - TSA)." annotation(
        Placement(transformation(origin = {-158, -80}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-228,-12},    extent={{-30,-30},
                {30,30}})));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yFanRet "Return fan speed command (0..1). Equals 0 when system not permissive; otherwise approx yFanSup - dYFanRet, limited to [yFanRetMin, 1]." annotation(
        Placement(transformation(origin={370,-4},     extent = {{-10, -10}, {10, 10}}), iconTransformation(origin={370,38},     extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanSup "Supply fan speed command (0..1). Equals 0 when system not permissive; otherwise equals modulated or minimum fan command." annotation(
        Placement(transformation(origin={370,190},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin={370,130},   extent = {{-10, -10}, {10, 10}})));
      // Parameters
      parameter Modelica.Units.SI.TemperatureDifference epsOn = 0.2 "Enter ‘SAT at minimum’ when (TSupSetMin - TSupSet) >= -epsOn (TSupSet within epsOn above TSupSetMin).";
      parameter Modelica.Units.SI.TemperatureDifference epsOff = 1.0 "Exit ‘SAT at minimum’ when (TSupSetMin - TSupSet) <= -epsOff (TSupSet moved away from TSupSetMin by epsOff).";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOn = 0.2 "Cooling-effective ON threshold: enable when (TRoo - TSA) >= dTSupOn (supply air is sufficiently cooler).";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOff = 0.05 "Cooling-effective OFF threshold: disable when (TRoo - TSA) <= dTSupOff.";
      parameter Modelica.Units.SI.TemperatureDifference eRooOn = 0.3 "Cooling-demand ON threshold: enable when (TRoo - TRooSet) >= eRooOn.";
      parameter Modelica.Units.SI.TemperatureDifference eRooOff = 0.05 "Cooling-demand OFF threshold: disable when (TRoo - TRooSet) <= eRooOff.";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Minimum supply air temperature setpoint during cooling.";
      parameter Modelica.Units.SI.TemperatureDifference dTSupFan = 2 "Offset above TSupSetMin used as the effective SAT threshold for fan-stage entry.";
      parameter Real yFanMin = 0.1 "Minimum allowed SA fan speed command (0..1)";
      parameter Real yFanMax = 1.00 "Maximum allowed SA fan speed command (0..1)";
      parameter Real dYFanRet = 0.05 "Return fan offset relative to supply fan: yFanRA = yFanSA - dYFanRet (then limited)";
      parameter Real yFanRetMin = 0.1 "Minimum allowed return fan speed";

      parameter Real kFan = 0.05 "Fan PI proportional gain.";
      parameter Modelica.Units.SI.Time TiFan = 900 "Fan PI integral time [s].";
      parameter Modelica.Units.SI.TemperatureDifference dTOverCooOn = 1.0 "Enter overcool protection when TRoo-TRooSet < -dTOverCooOn.";
      parameter Modelica.Units.SI.TemperatureDifference dTOverCooOff = 0.3 "Leave overcool protection when TRoo-TRooSet > -dTOverCooOff.";

      // control logic overview

      // Control logic
      Modelica.Blocks.Logical.Not notWin "True when window is NOT open" annotation(
        Placement(transformation(origin = {-92, 168}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And sysPerm "System permissive: sysOn AND notWin" annotation(
        Placement(transformation(origin = {-24, 190}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add errTRoo(k1 = +1, k2 = -1) "e=TRoo - TRooSet" annotation(
        Placement(transformation(origin = {-98, -4}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dTRooTSup(k1 = +1, k2 = -1)
        "Cooling effectiveness = TRoo - TSup"                                 annotation(
        Placement(transformation(origin = {-98, -60}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Hysteresis hysDem(uHigh = eRooOn, uLow = eRooOff)
        "Cooling demand flag with hysteresis based on TRoo-TRooSet"                                                                         annotation(
        Placement(transformation(origin = {-58, -4}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Hysteresis hysCooEffSup(uHigh = dTSupOn, uLow = dTSupOff)
        "Cooling effectiveness flag with hysteresis based on TRoo-TSup"                                                                                annotation(
        Placement(transformation(origin = {-58, -60}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetFan(k=TSupSetMin +
            dTSupFan) "Effective SAT threshold for fan-stage entry."                  annotation(
        Placement(transformation(origin = {-150, -152}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dTSupSetFan(k1 = -1, k2 = +1) "TSupSetFan - TSupSet" annotation(
        Placement(transformation(origin = {-100, -122}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Hysteresis hysTSupSetFan(uHigh = -epsOn, uLow = -epsOff)
        "True when TSupSet is close to TSupSetFan"                                                                                annotation(
        Placement(transformation(origin = {-56, -122}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And andDemEff "coolingDemand AND coolingEff" annotation(
        Placement(transformation(origin = {-18, -30}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conYFanMin(k = yFanMin) annotation(
        Placement(transformation(origin={244,106},   extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiFanMod
        "If enaFan then yFanMod else yFanMin"                                        annotation(
        Placement(transformation(origin={282,38},    extent={{-10,10},{10,-10}},      rotation = -0)));
      Modelica.Blocks.Logical.Switch swiFanSup "If sysPerm then yFanCmd else 0" annotation(
        Placement(transformation(origin={330,190},    extent = {{-10, 10}, {10, -10}}, rotation = -0)));
      Modelica.Blocks.Sources.Constant conDYFanRet(k = dYFanRet) annotation(
        Placement(transformation(origin={184,-100},    extent = {{10, 10}, {-10, -10}}, rotation = -180)));
      Modelica.Blocks.Math.Add subFanRet(k1 = +1, k2 = -1) "Compute yFanSA - dYFanRet" annotation(
        Placement(transformation(origin={224,-94},    extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiFanRet "If sysPerm then limited RA command else 0" annotation(
        Placement(transformation(origin={332,-4},     extent = {{-10, 10}, {10, -10}})));
      Modelica.Blocks.Nonlinear.Limiter limFanRet(uMax = 1, uMin = yFanRetMin) "Limit return fan command to [yFanRetMin, 1]" annotation(
        Placement(transformation(origin={254,-94},    extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conFanOff(k=0.03)  annotation(
        Placement(transformation(origin={290,224},    extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And andSta1
        "Enable fan PI only when SAT-first conditions are satisfied" annotation (
          Placement(transformation(origin={32,-22}, extent={{-10,-10},{10,10}})));
      Buildings.Controls.OBC.CDL.Reals.PID piFan(
        controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
        k=kFan,
        Ti=TiFan,
        yMax=yFanMax,
        yMin=yFanMin,
        reverseActing=false)
        "PI loop for supply fan, active only after SAT is near minimum"
        annotation (Placement(transformation(extent={{58,16},{86,44}})));
      Modelica.Blocks.Logical.And enaFanPI
        "Enable fan PI only when SAT-first conditions are satisfied" annotation (
          Placement(transformation(origin={62,-82}, extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Logical.Hysteresis hysOverCoo(uHigh=dTOverCooOn, uLow=
            dTOverCooOff)
                         "True when overcooled" annotation (Placement(
            transformation(origin={-56,-170}, extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Logical.And enaFanPI2
        "Enable fan PI only when SAT-first conditions are satisfied" annotation (
          Placement(transformation(origin={90,-162}, extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Logical.Not notOverCoo
        annotation (Placement(transformation(extent={{-2,-180},{18,-160}})));
      Modelica.Blocks.Math.Add errCold(k1=+1, k2=-1) "TRooSet - TRoo" annotation (
          Placement(transformation(origin={-92,54}, extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Logical.Not notSysPerm annotation (Placement(transformation(
              origin={52,130}, extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Logical.RSFlipFlop fanLat
        annotation (Placement(transformation(extent={{138,82},{160,60}})));
      Buildings.Controls.OBC.CDL.Logical.TrueFalseHold fanHol(trueHoldDuration=600,
          falseHoldDuration=300) annotation (Placement(transformation(origin={208,64},
              extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Interfaces.BooleanOutput fanStage
        "Latched second-stage fan cooling mode" annotation (Placement(
            transformation(extent={{362,-62},{386,-38}}), iconTransformation(extent
              ={{362,-62},{386,-38}})));
      Modelica.Blocks.Logical.Switch swiPidFan
        "make pid error = 0 when the system is off" annotation (Placement(
            transformation(
            origin={-22,100},
            extent={{-10,10},{10,-10}},
            rotation=-0)));
      Modelica.Blocks.Logical.Switch swiPidFanSta
        "Make fan PI error = 0 when fanStage is false" annotation (Placement(
            transformation(
            origin={40,74},
            extent={{-10,10},{10,-10}},
            rotation=-0)));
    equation
      // Permissive
      connect(sysOn, sysPerm.u1) annotation(
        Line(points = {{-152, 206}, {-36, 206}, {-36, 190}}, color = {255, 0, 255}));
      connect(winOpe, notWin.u) annotation(
        Line(points = {{-152, 168}, {-104, 168}}, color = {255, 0, 255}));
      connect(notWin.y, sysPerm.u2) annotation(
        Line(points={{-81,168},{-36,168},{-36,182}},        color = {255, 0, 255}));
      // Errors
      connect(TRoo, errTRoo.u1) annotation(
        Line(points={{-196,16},{-120,16},{-120,2},{-110,2}},
                                                           color = {0, 0, 127}));
      connect(TRooSet, errTRoo.u2) annotation(
        Line(points={{-198,-20},{-118,-20},{-118,-10},{-110,-10}},
                                                               color = {0, 0, 127}));
      connect(TRoo, dTRooTSup.u1) annotation(
        Line(points={{-196,16},{-138,16},{-138,-54},{-110,-54}},          color = {0, 0, 127}));
      connect(TSup, dTRooTSup.u2) annotation(
        Line(points = {{-158, -80}, {-110, -80}, {-110, -66}}, color = {0, 0, 127}));
      // Hysteresis checks
      connect(dTRooTSup.y, hysCooEffSup.u) annotation(
        Line(points={{-87,-60},{-70,-60}},      color = {0, 0, 127}));
      connect(errTRoo.y, hysDem.u) annotation(
        Line(points={{-87,-4},{-70,-4}},      color = {0, 0, 127}));

      connect(TSupSet,dTSupSetFan. u1) annotation(
        Line(points = {{-160, -116}, {-112, -116}}, color = {0, 0, 127}));
      connect(conTSupSetFan.y,dTSupSetFan. u2) annotation(
        Line(points = {{-138, -152}, {-112, -152}, {-112, -128}}, color = {0, 0, 127}));
      connect(dTSupSetFan.y,hysTSupSetFan. u) annotation(
        Line(points={{-89,-122},{-68,-122}},      color = {0, 0, 127}));

      connect(sysPerm.y, swiFanSup.u2) annotation(
        Line(points={{-13,190},{318,190}},      color = {255, 0, 255}));
      connect(swiFanMod.y, swiFanSup.u1) annotation(
        Line(points={{293,38},{318,38},{318,182}},        color = {0, 0, 127}));
      connect(conFanOff.y, swiFanSup.u3) annotation(
        Line(points={{302,224},{310,224},{310,198},{318,198}},
                                                            color = {0, 0, 127}));
      connect(swiFanSup.y, yFanSup) annotation(
        Line(points={{341,190},{370,190}},      color = {0, 0, 127}));
      connect(conDYFanRet.y, subFanRet.u2) annotation(
        Line(points={{195,-100},{212,-100}},                   color = {0, 0, 127}));
      connect(conFanOff.y, swiFanRet.u3) annotation(
        Line(points={{302,224},{310,224},{310,4},{320,4}},  color = {0, 0, 127}));
      connect(sysPerm.y, swiFanRet.u2) annotation(
        Line(points={{-13,190},{6,190},{6,-4},{320,-4}},                                        color = {255, 0, 255}));
      connect(subFanRet.y, limFanRet.u) annotation(
        Line(points={{235,-94},{242,-94}},      color = {0, 0, 127}));
      connect(limFanRet.y, swiFanRet.u1) annotation(
        Line(points={{265,-94},{312,-94},{312,-12},{320,-12}},
                                                            color = {0, 0, 127}));
      connect(swiFanRet.y, yFanRet) annotation(
        Line(points={{343,-4},{370,-4}},        color = {0, 0, 127}));
      connect(hysDem.y, andDemEff.u1) annotation(
        Line(points={{-47,-4},{-30,-4},{-30,-30}},        color = {255, 0, 255}));
      connect(hysCooEffSup.y, andDemEff.u2) annotation(
        Line(points={{-47,-60},{-30,-60},{-30,-38}},        color = {255, 0, 255}));
      connect(swiFanSup.y, subFanRet.u1) annotation(
        Line(points={{341,190},{350,190},{350,-76},{204,-76},{204,-88},{212,-88}},  color = {0, 0, 127}));
      connect(sysPerm.y, andSta1.u1) annotation (Line(points={{-13,190},{6,190},{6,-22},
              {20,-22}}, color={255,0,255}));
      connect(andDemEff.y, andSta1.u2)
        annotation (Line(points={{-7,-30},{20,-30}}, color={255,0,255}));
      connect(andSta1.y, enaFanPI.u1) annotation (Line(points={{43,-22},{48,-22},{48,
              -82},{50,-82}}, color={255,0,255}));
      connect(hysTSupSetFan.y, enaFanPI.u2) annotation (Line(points={{-45,-122},{50,
              -122},{50,-90}}, color={255,0,255}));
      connect(piFan.y, swiFanMod.u1)
        annotation (Line(points={{88.8,30},{270,30}},           color={0,0,127}));
      connect(conYFanMin.y, swiFanMod.u3) annotation (Line(points={{256,106},{262,106},
              {262,46},{270,46}},color={0,0,127}));
      connect(hysOverCoo.y, notOverCoo.u)
        annotation (Line(points={{-45,-170},{-4,-170}}, color={255,0,255}));
      connect(notOverCoo.y, enaFanPI2.u2)
        annotation (Line(points={{19,-170},{78,-170}}, color={255,0,255}));
      connect(enaFanPI.y, enaFanPI2.u1) annotation (Line(points={{73,-82},{74,-82},{
              74,-162},{78,-162}}, color={255,0,255}));
      connect(TRoo, piFan.u_m) annotation (Line(points={{-196,16},{52,16},{52,6},
              {72,6},{72,13.2}},
                             color={0,0,127}));
      connect(TRooSet, errCold.u1) annotation (Line(points={{-198,-20},{-152,-20},{-152,
              60},{-104,60}}, color={0,0,127}));
      connect(TRoo, errCold.u2) annotation (Line(points={{-196,16},{-166,16},{-166,48},
              {-104,48}}, color={0,0,127}));
      connect(errCold.y, hysOverCoo.u) annotation (Line(points={{-81,54},{-82,54},{-82,
              -170},{-68,-170}}, color={0,0,127}));
      connect(sysPerm.y, notSysPerm.u) annotation (Line(points={{-13,190},{6,190},{6,
              130},{40,130}}, color={255,0,255}));
      connect(enaFanPI2.y, fanLat.S) annotation (Line(points={{101,-162},{106,-162},
              {106,64.4},{135.8,64.4}}, color={255,0,255}));
      connect(fanLat.Q, fanHol.u) annotation (Line(points={{161.1,64.4},{178.55,64.4},
              {178.55,64},{196,64}}, color={255,0,255}));
      connect(fanHol.y, swiFanMod.u2) annotation (Line(points={{220,64},{260,64},{260,
              38},{270,38}}, color={255,0,255}));
      connect(fanHol.y, fanStage) annotation (Line(points={{220,64},{242,64},{242,-50},
              {374,-50}}, color={255,0,255}));
      connect(notSysPerm.y, fanLat.R) annotation (Line(points={{63,130},{126,130},{126,
              77.6},{135.8,77.6}}, color={255,0,255}));
      connect(sysPerm.y, swiPidFan.u2) annotation (Line(points={{-13,190},{6,
              190},{6,130},{-72,130},{-72,100},{-34,100}}, color={255,0,255}));
      connect(TRooSet, swiPidFan.u1) annotation (Line(points={{-198,-20},{-152,
              -20},{-152,92},{-34,92}}, color={0,0,127}));
      connect(TRoo, swiPidFan.u3) annotation (Line(points={{-196,16},{-166,16},
              {-166,108},{-34,108}}, color={0,0,127}));
      connect(swiPidFan.y, swiPidFanSta.u1) annotation (Line(points={{-11,100},
              {16,100},{16,66},{28,66}}, color={0,0,127}));
      connect(fanHol.y, swiPidFanSta.u2) annotation (Line(points={{220,64},{222,
              64},{222,104},{28,104},{28,74}}, color={255,0,255}));
      connect(TRoo, swiPidFanSta.u3) annotation (Line(points={{-196,16},{-166,
              16},{-166,82},{28,82}}, color={0,0,127}));
      connect(swiPidFanSta.y, piFan.u_s) annotation (Line(points={{51,74},{56,
              74},{56,50},{48,50},{48,30},{55.2,30}}, color={0,0,127}));
      annotation(
        Diagram(coordinateSystem(extent={{-200,-240},{360,240}})),
        Icon(coordinateSystem(extent={{-200,-240},{360,240}}),
             graphics = {Rectangle(extent={{-198,240},{360,-240}}),      Bitmap(origin={80,-2},    extent={{-276,
                  -238},{276,238}},                                                                                                 imageSource = "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")}));
    end FanPICtrl;

    model PIController
      // Inputs
      Modelica.Blocks.Interfaces.RealInput TRoo annotation(
        Placement(transformation(origin = {-122, 30}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 40}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet annotation(
        Placement(transformation(origin = {-120, -36}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 0}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSup annotation(
        Placement(transformation(origin = {-120, 88}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput CO2Set annotation(
        Placement(transformation(origin = {-125, -181}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, -80}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput CO2Meas annotation(
        Placement(transformation(origin = {-125, -217}, extent = {{-17, -17}, {17, 17}}), iconTransformation(origin = {-120, -40}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn annotation(
        Placement(transformation(origin = {-124, -102}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe annotation(
        Placement(transformation(origin = {-124, -138}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yValChi annotation(
        Placement(transformation(origin = {252, 76}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 46}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yPumChi annotation(
        Placement(transformation(origin = {250, 42}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 82}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanSup annotation(
        Placement(transformation(origin={258,-40},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -10}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yFanRet annotation(
        Placement(transformation(origin={258,-66},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -44}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yDamOut annotation(
        Placement(transformation(origin = {252, -200}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -82}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      // Parameters
      // ---- SAT / hydronic loop tuning ----
      parameter Modelica.Units.SI.TemperatureDifference dTDb = 0.2 "SAT reset deadband (K)";
      parameter Modelica.Units.SI.TemperatureDifference dTMax = 2 "Room error that drives SAT to TSupSetMin (K)";
      parameter Modelica.Units.SI.Temperature TSupSetMax = 273.15 + 40 "Max SAT setpoint when no cooling demand (K)";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Minimum cooling SAT setpoint (K)";

      parameter Real kVal = 0.190 "PI proportional gain for valve loop";
      parameter Modelica.Units.SI.Time TiVal = 5820 "PI integral time for valve loop (s)";

      parameter Real kSatReset = 1.890 "SAT PI proportional gain.";
      parameter Modelica.Units.SI.Time TiSatReset = 309.6 "SAT integral time.";

      parameter Real yValMin = 0.01 "Minimum allowed valve opening command (0..1)";

      // ---- Fan loop tuning ----
      parameter Modelica.Units.SI.TemperatureDifference eRooOn = 0.3 "Enable cooling demand when TRoo-TRooSet >= eRooOn (K)";
      parameter Modelica.Units.SI.TemperatureDifference eRooOff = 0.05 "Disable cooling demand when TRoo-TRooSet <= eRooOff (K)";
      parameter Modelica.Units.SI.TemperatureDifference epsOn = 0.1 "Fan enabled when SATSP-TSupSetMin <= epsOn (K)";
      parameter Modelica.Units.SI.TemperatureDifference epsOff = 0.5 "Fan disabled when SATSP-TSupSetMin >= epsOff (K)";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOn = 0.2 "Cooling-effective when TRoo-TSA >= dTSupOn (K)";
      parameter Modelica.Units.SI.TemperatureDifference dTSupOff = 0.05 "Not cooling-effective when TRoo-TSA <= dTSupOff (K)";
      parameter Real yFanMin = 0.07 "Minimum fan speed (0..1)";
      parameter Real yFanMax = 1.00 "Maximum fan speed (0..1)";
      parameter Real dYFanRet = 0.05 "Return fan offset (Ret = Sup - dYFanRet)";
      parameter Real yFanRetMin = 0.07 "Minimum return air fan speed (0..1)";

      parameter Real kFan = 0.0723 "Fan PI proportional gain.";
      parameter Modelica.Units.SI.Time TiFan = 1654 "Fan PI integral time [s].";

      // ---- OA / CO2 loop tuning ----
      parameter Real yOAMin = 0.10 "Minimum outdoor air damper command (0..1)";
      parameter Real yOAMax = 1.00 "Maximum outdoor air damper command (0..1)";
      parameter Real kOA = 0.005 "OA damper PI proportional gain";
      parameter Modelica.Units.SI.Time TiOA = 500 "OA damper PI integral time [s]";
      // Sub-controllers
      //
      //
      //
      FanPICtrl fanPICtrl(
        epsOn=epsOn,
        epsOff=epsOff,
        dTSupOn=dTSupOn,
        dTSupOff=dTSupOff,
        eRooOn=eRooOn,
        eRooOff=eRooOff,
        TSupSetMin=TSupSetMin,
        yFanMin=yFanMin,
        yFanMax=yFanMax,
        dYFanRet=dYFanRet,
        yFanRetMin=yFanRetMin,
        kFan=kFan,
        TiFan=TiFan)
        annotation (Placement(transformation(extent={{114,-88},{202,-12}})));

      HydronicTSupPICtrl hydronicTSupPICtrl(
        dTDb=dTDb,
        dTMax=dTMax,
        TSupSetMax=TSupSetMax,
        TSupSetMin=TSupSetMin,
        kVal=kVal,
        TiVal=TiVal,
        kSatReset=kSatReset,
        TiSatReset=TiSatReset,
        yValMin=yValMin)
        annotation (Placement(transformation(extent={{-14,32},{72,118}})));

      OAPICtrl oaPICtrl(
        yOAMin=yOAMin,
        yOAMax=yOAMax,
        kOA=kOA,
        TiOA=TiOA)
        annotation (Placement(transformation(extent={{20,-168},{-42,-230}})));

      // Delay window-open enable seen by the subcontrollers.
      // During AC -> NV transition, this keeps the HVAC path active briefly so
      // fan/valve commands can ramp down before the natural-ventilation path opens.
      Modelica.Blocks.Logical.LogicalDelay delWinOpe(delayTime=180)
        annotation (Placement(transformation(extent={{-74,-148},{-54,-128}})));

      // Delay AC enable seen by the subcontrollers.
      // During NV -> AC transition, this lets the window path settle before
      // the HVAC controllers re-enter active cooling mode.
      Modelica.Blocks.Logical.LogicalDelay delSysOn(delayTime=120)
        annotation (Placement(transformation(extent={{-76,-112},{-56,-92}})));
    equation
      connect(TRoo, fanPICtrl.TRoo) annotation (Line(points={{-122,30},{-100,30},{-100,
              -20},{104,-20},{104,-20.075},{109.443,-20.075}}, color={0,0,127}));
      connect(TRooSet, fanPICtrl.TRooSet) annotation (Line(points={{-120,-36},{-5.2785,
              -36},{-5.2785,-35.9083},{109.443,-35.9083}}, color={0,0,127}));
      connect(TSup, fanPICtrl.TSup) annotation (Line(points={{-120,88},{-36,88},{-36,
              126},{90,126},{90,-52},{102,-52},{102,-51.9},{109.6,-51.9}}, color={0,
              0,127}));
      connect(fanPICtrl.yFanSup, yFanSup) annotation (Line(points={{203.571,-29.4167},
              {242,-29.4167},{242,-40},{258,-40}}, color={0,0,127}));

      connect(fanPICtrl.yFanRet, yFanRet) annotation (Line(points={{203.571,-43.9833},
              {242,-43.9833},{242,-66},{258,-66}}, color={0,0,127}));
      connect(TSup, hydronicTSupPICtrl.TSup) annotation (Line(points={{-120,88},{-36,
              88},{-36,104.24},{-22.6,104.24}}, color={0,0,127}));
      connect(TRoo, hydronicTSupPICtrl.TRoo) annotation (Line(points={{-122,30},{-100,
              30},{-100,70},{-22.6,70},{-22.6,75.86}}, color={0,0,127}));
      connect(TRooSet, hydronicTSupPICtrl.TRooSet) annotation (Line(points={{-120,-36},
              {-22.6,-36},{-22.6,50.06}}, color={0,0,127}));
      connect(fanPICtrl.fanStage, hydronicTSupPICtrl.fanStage) annotation (Line(
            points={{204.2,-57.9167},{226,-57.9167},{226,0},{61.68,0},{61.68,23.4}},
            color={255,0,255}));
      connect(hydronicTSupPICtrl.yValChi, yValChi) annotation (Line(points={{76.3,93.92},
              {252,93.92},{252,76}}, color={0,0,127}));
      connect(hydronicTSupPICtrl.yPumChi, yPumChi) annotation (Line(points={{76.3,56.94},
              {250,56.94},{250,42}}, color={0,0,127}));
      connect(hydronicTSupPICtrl.TSupSet, fanPICtrl.TSupSet) annotation (Line(
            points={{76.3,38.02},{100,38.02},{100,-66.7833},{109.286,-66.7833}},
            color={0,0,127}));
      connect(CO2Set,oaPICtrl. CO2Set) annotation (Line(points={{-125,-181},{-126,-180.4},
              {-48.2,-180.4}}, color={0,0,127}));
      connect(CO2Meas,oaPICtrl. CO2Meas) annotation (Line(points={{-125,-217},{-48.2,
              -217},{-48.2,-214.5}}, color={0,0,127}));
      connect(oaPICtrl.yDamOut, yDamOut) annotation (Line(points={{23.1,-199},{137.55,
              -199},{137.55,-200},{252,-200}}, color={0,0,127}));
      connect(winOpe, delWinOpe.u)
        annotation (Line(points={{-124,-138},{-76,-138}}, color={255,0,255}));
      connect(delWinOpe.y2, oaPICtrl.winOpe) annotation (Line(points={{-53,-144},{-1.08,
              -144},{-1.08,-161.8}}, color={255,0,255}));
      connect(delWinOpe.y2, hydronicTSupPICtrl.winOpe) annotation (Line(points={{-53,
              -144},{16.1,-144},{16.1,23.4}}, color={255,0,255}));
      connect(delWinOpe.y2, fanPICtrl.winOpe) annotation (Line(points={{-53,-144},{146,
              -144},{146,-118},{144.486,-118},{144.486,-92.75}}, color={255,0,255}));
      connect(sysOn, delSysOn.u)
        annotation (Line(points={{-124,-102},{-78,-102}}, color={255,0,255}));
      connect(delSysOn.y2, hydronicTSupPICtrl.sysOn) annotation (Line(points={{-55,-108},
              {-5.4,-108},{-5.4,23.4}}, color={255,0,255}));
      connect(delSysOn.y2, fanPICtrl.sysOn) annotation (Line(points={{-55,-108},{129.4,
              -108},{129.4,-93.0667}}, color={255,0,255}));
      connect(delSysOn.y2, oaPICtrl.sysOn) annotation (Line(points={{-55,-108},{8,-108},
              {8,-161.8},{13.8,-161.8}}, color={255,0,255}));
      annotation(
        Diagram(coordinateSystem(extent = {{-140, 120}, {260, -260}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-1, 9}, extent = {{-87, 63}, {87, -63}}, imageSource = "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")}));
    end PIController;

    model HydronicTSupPICtrl
      // ---------------------------------------------------------------------------
      // Supervisory SAT reset PI.
      // Uses room temperature error to generate the occupied SAT setpoint.
      // With reverseActing=true:
      // - TRoo > TRooSet -> colder SAT setpoint
      // - TRoo < TRooSet -> warmer SAT setpoint

      // ---------------------------------------------------------------------------
      // Inputs
      Modelica.Blocks.Interfaces.RealInput TRoo "Room/zone air temperature measurement [K]. Used to compute cooling demand (TRoo-TRooSet)." annotation(
        Placement(transformation(origin={-120,2},     extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-120,2},    extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet "Room/zone temperature setpoint [K]. Compared with TRoo to determine SAT reset level." annotation(
        Placement(transformation(origin={-120,28},     extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, -58}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSup "Supply air temperature measurement [K] (downstream of coil/supply duct sensor). Controlled variable for the PI loop." annotation(
        Placement(transformation(origin = {-120, -88}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 68}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC allowed to operate). If false, valve and pump are forced OFF." annotation(
        Placement(transformation(origin = {-116, 184}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open / natural ventilation flag (true = window open). If true, valve and pump are forced OFF." annotation(
        Placement(transformation(origin = {-116, 146}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin={-30,-120},    extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yValChi "Cooling coil valve command (0..1). When enabled, equals max(PI, ValMinOn); when disabled, equals ValOff." annotation(
        Placement(transformation(origin = {314, 168}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 44}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yPumChi "Hydronic pump command (0/1). ON when system is enabled AND windows are closed." annotation(
        Placement(transformation(origin = {314, 224}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -42}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput TSupSet
        "Calculated SAT setpoint [K]. Reset from TSupSetMax toward TSupSetFan as room temperature error increases."                                                                annotation(
        Placement(transformation(origin={316,6},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -86}, extent = {{-10, -10}, {10, 10}})));
      // Parameters
      parameter Modelica.Units.SI.TemperatureDifference dTDb = 0.2 "SAT reset deadband [K]. No SAT reset until (TRoo-TRooSet) exceeds dTDb, which prevents hunting around setpoint.";
      parameter Modelica.Units.SI.TemperatureDifference dTMax = 2 "Room temperature error [K] that drives SAT fully to TSupSetFan. Larger value makes SAT reset less aggressive.";
      parameter Modelica.Units.SI.Temperature TSupSetMax = 273.15 + 40 "Max SAT [K] used when there is little/no cooling demand (typically warmer to save energy).";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Absolute minimum SAT limit [K]. Not normally used by supervisory SAT reset.";
      parameter Modelica.Units.SI.TemperatureDifference dTSupFan = 2 "Offset above TSupSetMin used as the effective SAT level for fan-stage operation.";
      parameter Real kVal = 0.05 "Valve PI proportional gain. Higher kVal increases responsiveness but can increase oscillation.";
      parameter Modelica.Units.SI.Time TiVal = 300 "Valve PI integral time [s]. Smaller TiVal integrates faster (removes offset faster) but may cause instability.";

      parameter Real kSatReset = 1.25 "SAT PI proportional gain.";
      parameter Modelica.Units.SI.Time TiSatReset = 360 "SAT integral time.";

      parameter Modelica.Units.SI.Temperature TSupSetOff = 273.15 + 40
      "SAT setpoint when system is off";

       parameter Real yValMin = 0.01 "Minimum allowed valve opening command (0..1)";
      // ---------------------------------------------------------------------------
      // Control logic blocks
      // ---------------------------------------------------------------------------
    // sysPerm = sysOn AND not winOpe.
    // This permissive enables pump/valve operation and selects occupied SAT logic.

      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetFan(k=TSupSetMin +
            dTSupFan)
        "Effective minimum SAT target used by normal reset and fan-stage operation [K]."                          annotation(
        Placement(transformation(origin={8,64},     extent = {{-10, -10}, {10, 10}})));
    // Valve tracking PI.
    // Tracks the final SAT setpoint (after fan-stage and off-mode overrides)
    // using the chilled-water valve.
      Buildings.Controls.OBC.CDL.Reals.PID pidVal(controllerType = Buildings.Controls.OBC.CDL.Types.SimpleController.PI, k = kVal, Ti = TiVal, reverseActing = false, yMax = 1, yMin = 0)
        "PI loop controlling valve (y) to drive measured TSA (u_m) toward SATSP (u_s)."                                                                                                                         annotation(
        Placement(transformation(origin = {204, 34}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      // System permissive logic:
      // enable = sysOn AND (NOT winOpen)
      Modelica.Blocks.Logical.Not notWinOpe "Logical NOT of winOpen. If winOpen = true, then notWin = false; If winOpen = false, then notWin = true." annotation(
        Placement(transformation(origin = {-56, 146}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And sysPerm "Enable signal: sysOn AND notWin. Used to enable pump and valve operation." annotation(
        Placement(transformation(origin = {12, 168}, extent = {{-10, -10}, {10, 10}})));
      // Valve handling when enabled:
      // yVal_on = max(conPID.y, ValMinOn) to avoid sticking and to ensure some minimum flow
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conValMinOn(k=yValMin)
                                                                              "Minimum valve opening when enabled (0..1). Prevents valve sticking and improves numerical robustness." annotation(
        Placement(transformation(origin={206,80},    extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Max maxVal "Selects the larger of PI output and ValMinOn." annotation(
        Placement(transformation(origin = {244, 58}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conValOff(k=0.0)   "Valve command when disabled (normally 0)." annotation(
        Placement(transformation(origin={204,192},    extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiVal "Valve enable switch: if andSys=true -> output maxVal; else -> ValOff." annotation(
        Placement(transformation(origin = {274, 168}, extent = {{-10, 10}, {10, -10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Conversions.BooleanToReal pumCmd(realTrue=0.8,
          realFalse=0.0)                                                                           "Converts enable boolean to pump command (1=ON, 0=OFF)." annotation(
        Placement(transformation(origin = {118, 224}, extent = {{-10, -10}, {10, 10}})));

    // Fan-stage override.
    // Once the SAT-first sequence has reached fan stage, force SAT setpoint
    // to TSupSetFan and let the fan loop provide the extra cooling capacity.
      Modelica.Blocks.Interfaces.BooleanInput fanStage
        "If true, force TSupSet to TSupSetFan during second-stage fan cooling."
        annotation (Placement(transformation(
            extent={{-20,-20},{20,20}},
            rotation=90,
            origin={76,-120}), iconTransformation(
            extent={{-20,-20},{20,20}},
            rotation=90,
            origin={76,-120})));

      Modelica.Blocks.Logical.Switch swiTSupSet
        "If fanStage=true, force TSupSetFan; else use normal TSupSetCal"
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=0,
            origin={66,56})));
      Buildings.Controls.OBC.CDL.Reals.PID pidTSupSet(
        controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
        k=kSatReset,
        Ti=TiSatReset,
        reverseActing=true,
        yMax=TSupSetMax,
        yMin=TSupSetMin) "PI loop." annotation (Placement(transformation(
            origin={8,20},
            extent={{-10,-10},{10,10}},
            rotation=-0)));
      Modelica.Blocks.Logical.Switch swiTSupSetOn
        annotation (Placement(transformation(extent={{114,38},{134,58}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetOff(k=TSupSetOff)
        "Off-mode SAT setpoint" annotation (Placement(transformation(origin={66,0},
              extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Logical.Switch swiPidValSet
        annotation (Placement(transformation(extent={{150,-24},{170,-4}})));
      Modelica.Blocks.Logical.Switch swiPidTSupSet
        "Make supervisory SAT-reset PI error = 0 when system is off"
        annotation (Placement(transformation(extent={{-70,10},{-50,30}})));
    equation
      connect(TSup, pidVal.u_m) annotation(
        Line(points = {{-120, -88}, {204, -88}, {204, 22}}, color = {0, 0, 127}));
      connect(sysOn, sysPerm.u1) annotation(
        Line(points = {{-116, 184}, {0, 184}, {0, 168}}, color = {255, 0, 255}));
      connect(winOpe, notWinOpe.u) annotation(
        Line(points = {{-116, 146}, {-68, 146}}, color = {255, 0, 255}));
      connect(notWinOpe.y, sysPerm.u2) annotation(
        Line(points={{-45,146},{0,146},{0,160}},        color = {255, 0, 255}));
      connect(pidVal.y, maxVal.u2) annotation(
        Line(points = {{216, 34}, {232, 34}, {232, 52}}, color = {0, 0, 127}));
      connect(conValMinOn.y, maxVal.u1) annotation(
        Line(points={{218,80},{232,80},{232,64}},        color = {0, 0, 127}));
      connect(maxVal.y, swiVal.u1) annotation(
        Line(points={{255,58},{262,58},{262,160}},        color = {0, 0, 127}));
      connect(conValOff.y, swiVal.u3) annotation(
        Line(points={{216,192},{262,192},{262,176}},        color = {0, 0, 127}));
      connect(swiVal.y, yValChi) annotation(
        Line(points={{285,168},{314,168}},      color = {0, 0, 127}));
      connect(sysPerm.y, pumCmd.u) annotation(
        Line(points={{23,168},{106,168},{106,224}},        color = {255, 0, 255}));
      connect(pumCmd.y, yPumChi) annotation(
        Line(points = {{130, 224}, {314, 224}}, color = {0, 0, 127}));
      connect(sysPerm.y, swiVal.u2) annotation(
        Line(points={{23,168},{262,168}},      color = {255, 0, 255}));
      connect(fanStage, swiTSupSet.u2) annotation (Line(points={{76,-120},{76,-100},
              {30,-100},{30,56},{54,56}},
                         color={255,0,255}));

      connect(TRoo, pidTSupSet.u_m)
        annotation (Line(points={{-120,2},{8,2},{8,8}}, color={0,0,127}));
      connect(swiTSupSet.y, swiTSupSetOn.u1)
        annotation (Line(points={{77,56},{112,56}},  color={0,0,127}));
      connect(sysPerm.y, swiTSupSetOn.u2) annotation (Line(points={{23,168},{106,168},
              {106,48},{112,48}}, color={255,0,255}));
      connect(conTSupSetOff.y, swiTSupSetOn.u3)
        annotation (Line(points={{78,0},{100,0},{100,40},{112,40}},
                                                            color={0,0,127}));
      connect(swiTSupSetOn.y, TSupSet) annotation (Line(points={{135,48},{184,48},{184,
              14},{300,14},{300,6},{316,6}},
                           color={0,0,127}));
      connect(conTSupSetFan.y, swiTSupSet.u1)
        annotation (Line(points={{20,64},{54,64}},         color={0,0,127}));
      connect(pidTSupSet.y, swiTSupSet.u3) annotation (Line(points={{20,20},{40,20},
              {40,48},{54,48}}, color={0,0,127}));
      connect(swiTSupSetOn.y, swiPidValSet.u1) annotation (Line(points={{135,48},{140,
              48},{140,-6},{148,-6}}, color={0,0,127}));
      connect(sysPerm.y, swiPidValSet.u2) annotation (Line(points={{23,168},{106,168},
              {106,-14},{148,-14}}, color={255,0,255}));
      connect(TSup, swiPidValSet.u3) annotation (Line(points={{-120,-88},{148,-88},{
              148,-22}}, color={0,0,127}));
      connect(swiPidValSet.y, pidVal.u_s) annotation (Line(points={{171,-14},{172,-14},
              {172,34},{192,34}}, color={0,0,127}));
      connect(TRooSet, swiPidTSupSet.u1)
        annotation (Line(points={{-120,28},{-72,28}}, color={0,0,127}));
      connect(sysPerm.y, swiPidTSupSet.u2) annotation (Line(points={{23,168},{32,168},
              {32,108},{-72,108},{-72,20}}, color={255,0,255}));
      connect(TRoo, swiPidTSupSet.u3)
        annotation (Line(points={{-120,2},{-72,2},{-72,12}}, color={0,0,127}));
      connect(swiPidTSupSet.y, pidTSupSet.u_s)
        annotation (Line(points={{-49,20},{-4,20}}, color={0,0,127}));
      annotation(
        Diagram(coordinateSystem(extent = {{-140, 240}, {320, -120}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {0, 48}, rotation = 180, extent = {{-98, 50}, {98, -50}}, imageSource = "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gs8fMyE0YJrbZ7HzWmFpUGZvwX1V2oilIIT88RJGA1zfjBvSG0uDsfB13FOlAixFYeSPlVAa8DFuUqn0QAivB+tPdz395w9Y6xBK/jgJpwEf4TZnLTuGtblaeQXu46y3s38QFU7+GAmnAfkHcaOzSv+vD1bnYkE/3ME5N+zDaqdw8sdISA04PBO3Omf+xIFYruu+TU1w9XPWejkVIaT88XEBxsvegAuwIp19HXCzKrbX8PB/M7thn7u89j9lZz7WpxNW/tgozhrP0aJirEir0PWZYIVuz2T/85xF/rTXcNWqrsH69ELLHxe9MN5bWPEWVnj9dLeX2/sBp2xuOgI38KP+O64v/SqU/hI3cBFi/njYhvFGlqcWlI/Eim2pBe62ubw7d8beA9pXj+06kPnCnxOe30gNM38sHMN4Cno3Bm9X3l/ILcp8Nyn1r2c0ngwc7tsV1wEbVuI2rkLNHwf3YDzV5HjV2487n2bfU/X2zF7NeoZ+yzXL38etMlnwTIeWuAZ63ccnj+Hmj4HyVZhPnazy/KzwJN6qVsFjZEYvu78hcFbR2Esewe3Su7ngXy6fNFXVzs+7jSHnj4E0L9e++bTyxk+/wduU6pC6fTYXtcUF0llye8ETGd8gennlptFLcKt0GkzDTTMLO794T2HAiqdn+099v8OO/XvxFqXUU7hCFu1b4wpuhtwxcUyny+Ajw56XHdt21c+HYK2b62qnbp5V6Pmlq5/+f+j2tWu347+d0tbPA+wpA10/q02vQbexB0872XWZz8s853l59y9F+PmlW4sRM1uL23uwbT6uEo75y3HPHkSQX7Z/Y8TM/o3be9FmPC4TgtI9Kc/fvYoiv2wenqifcxC39qi35lf2eHfvQtynR5Hkl6y2h5dWlZr5fY51VvkPQ/07sKqG9sUn0eSXzPGRqLtcPgq9c2fGDwdyUTJvMO7Nh4jyyzXY84usIbn0OS/v29twwWB0r4Z78iWy/GK134BJ09vQHrf0q3eGE0U0lZ5cgXvxK7r8Um319OBcuhW30/DqGh9/crO7a4/Ht5EzijC/UJ6+VmMibqXn06M+391x98/pu3F1PVHml2mT66nVlUo24Tba+vwn48k8Xi37T8aPD3yJNL9Ij2b57L7sUdwiJyuOPoh78OfBo6/gmjmJOL9AjyzDzFUtC+JPbYr8lTu/h3vxqqzdVE+nfPoRdX55Vhe7XNirVOfi1VgdhGFPd/gEd5XdGx8sPowrBSH6/OIc6VeE0SsU9TuClcFpuLGdjycEr+35sgWuEBwT+YX5+kAdjF/nwNdYFbTdffvVaoD7RQ1enPePgJ7zuzOTX5TCap9tPvuMuGTzZ9VyPoHfoynH+hffMSDNK8QTrQ8++07j87A+JMbyS5J/5Nutn3++9dsjgT/Tyqqw55E55zeevPydH7009ydPN3/l5i7rtT/l0WYwPxERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER6fh/H7w6my0mDdAAAAAASUVORK5CYII="), Bitmap(origin = {0, -48}, rotation = 180, extent = {{-98, 52}, {98, -52}}, imageSource = "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")}));
    end HydronicTSupPICtrl;

    model OAPICtrl
    "CO2-based outdoor air (OA) damper PI controller"

      // ---------------------------------------------------------------------------
      // Outdoor air damper controller (DCV by CO2, PI-based)
      //
      // What it does:
      // - Computes an effective CO2 control setpoint:
      //       CO2Start = CO2Set + CO2Db_ppm
      // - Uses a PI controller to modulate the OA damper based on the difference
      //   between measured CO2 and CO2Start.
      // - The PI output is limited between yOAMin and yOAMax.
      //
      // Control behavior:
      // - If CO2Meas is above CO2Start, the OA damper opens further.
      // - If CO2Meas falls back toward or below CO2Start, the OA damper closes
      //   toward yOAMin.
      // - The PI output is bounded so that the damper never goes below yOAMin
      //   during enabled operation and never exceeds yOAMax.
      //
      // Enable / disable:
      // - If sysOn = true AND winOpe = false, output the PI-controlled OA command.
      // - Otherwise, output offDamOA (typically 0).
      //
      // Notes:
      // - CO2Db_ppm shifts the effective control point upward to reduce hunting
      //   around the nominal CO2 setpoint.

      // ---------------------------------------------------------------------------

      // Inputs
      Modelica.Blocks.Interfaces.RealInput CO2Meas "Measured zone/return CO2 concentration [ppm]." annotation(
        Placement(transformation(origin={195,23},     extent = {{17, -17}, {-17, 17}}), iconTransformation(origin = {120, 50}, extent = {{20, -20}, {-20, 20}})));
      Modelica.Blocks.Interfaces.RealInput CO2Set "CO2 control setpoint [ppm]. Effective PI setpoint is CO2Set + CO2Db_ppm." annotation(
        Placement(transformation(origin={193,85},    extent = {{17, -17}, {-17, 17}}), iconTransformation(origin = {120, -60}, extent = {{20, -20}, {-20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC allowed to operate). When false, damper is forced to offDamOA." annotation(
        Placement(transformation(origin={168,-18},    extent = {{20, -20}, {-20, 20}}, rotation = -0), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open / natural ventilation flag (true = open). When true, damper is forced to offDamOA." annotation(
        Placement(transformation(origin={170,-56},    extent = {{20, -20}, {-20, 20}}, rotation = -0), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Output
      Modelica.Blocks.Interfaces.RealOutput yDamOut "OA damper command (0..1)" annotation(
        Placement(transformation(origin={-240,-18},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}})));
      // Parameters
      parameter Real yOAMin = 0.10 "Minimum OA damper position (0..1). Also used as the lower PI output limit.";
      parameter Real yOAMax = 1.00 "Maximum OA damper position (0..1). Used as the upper PI output limit.";

      parameter Real kOA = 0.005 "OA damper PI proportional gain";
      parameter Modelica.Units.SI.Time TiOA = 500 "OA damper PI integral time [s]";
      // ---------------------------------------------------------------------------
      // Core CO2 ramp computation
      // ---------------------------------------------------------------------------
      // Effective ramp start = CO2Set + CO2Db_ppm
      // Error relative to ramp start: CO2Err = CO2Meas - CO2Start
      // Span of the CO2 ramp: span = CO2Max_ppm - co2Start
      // Normalized CO2 ramp position: norm = (CO2Meas - CO2Start) / span
      // Damper range: dY = yOAMax - yOAMin
      // Scale normalized demand into damper span: mul = limCO2 * dY
      // Add minimum: yOA = yOAMin + mul
      // ---------------------------------------------------------------------------
      // Enable / disable gating
      // ---------------------------------------------------------------------------
      Modelica.Blocks.Logical.Not notWin "notWin = NOT(winOpen). True when windows are closed and HVAC OA control is permitted." annotation(
        Placement(transformation(origin={106,-56},    extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Logical.And sysPerm "Enable signal for OA control: andSys = sysOn AND notWin." annotation(
        Placement(transformation(origin={24,-18},    extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant offDamOA(k=0.01)
                                                                        "Damper command when disabled (typically 0)." annotation(
        Placement(transformation(origin={-170,-54},    extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Modelica.Blocks.Logical.Switch swiDamOA "Output selection: if enabled -> use computed OA damper; else -> use offDamOA." annotation(
        Placement(transformation(origin={-206,-18},    extent = {{10, -10}, {-10, 10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Reals.PID pidOA(
        controllerType=Buildings.Controls.OBC.CDL.Types.SimpleController.PI,
        k=kOA,
        Ti=TiOA,
        yMax=yOAMax,
        yMin=yOAMin,
        reverseActing=false) "PI loop for OA damper based on CO2"
        annotation (Placement(transformation(extent={{46,70},{16,100}})));
    equation
      connect(winOpe, notWin.u) annotation(
        Line(points={{170,-56},{118,-56}},      color = {255, 0, 255}));
      connect(sysOn, sysPerm.u1) annotation(
        Line(points={{168,-18},{36,-18}},      color = {255, 0, 255}));
      connect(notWin.y, sysPerm.u2) annotation(
        Line(points={{95,-56},{36,-56},{36,-26}},         color = {255, 0, 255}));
      connect(sysPerm.y, swiDamOA.u2) annotation(
        Line(points={{13,-18},{-194,-18}},      color = {255, 0, 255}));
      connect(offDamOA.y, swiDamOA.u3) annotation(
        Line(points={{-182,-54},{-194,-54},{-194,-26}},        color = {0, 0, 127}));
      connect(swiDamOA.y, yDamOut) annotation(
        Line(points={{-217,-18},{-240,-18}},      color = {0, 0, 127}));
      connect(CO2Meas, pidOA.u_m)
        annotation (Line(points={{195,23},{31,23},{31,67}},   color={0,0,127}));
      connect(pidOA.y, swiDamOA.u1)
        annotation (Line(points={{13,85},{-194,85},{-194,-10}}, color={0,0,127}));
      connect(CO2Set, pidOA.u_s)
        annotation (Line(points={{193,85},{49,85}}, color={0,0,127}));
      annotation(
        Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-1, 1}, extent = {{-85, -65}, {85, 65}}, imageSource = "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")}),
        Diagram(coordinateSystem(extent = {{-240, 160}, {220, -120}})));
    end OAPICtrl;

    model HydronicTSupPICtrl_old
      // ---------------------------------------------------------------------------
      // Hydronic supply-air-temperature (SAT) controller
      //
      // What it does:
      // 1) Computes a SAT setpoint (SATSP) from room temperature error (TRoo-TRooSet)
      //    using a linear reset between TSupSetMax and TSupSetFan with a deadband.
      // 2) Runs a PI loop to track SATSP using the cooling coil valve (yVal).
      // 3) Enables/disables valve and pump based on system enable and window status.
      //
      // Notes:
      // - The valve is forced OFF when the system is not allowed to run.
      // - When enabled, the valve command is at least ValMinOn to avoid “stiction”
      //   and to keep the coil loop responsive at low loads.
      // - Pump is commanded ON whenever the system is enabled and windows are closed.
      // ---------------------------------------------------------------------------
      // Inputs
      Modelica.Blocks.Interfaces.RealInput TRoo "Room/zone air temperature measurement [K]. Used to compute cooling demand (TRoo-TRooSet)." annotation(
        Placement(transformation(origin = {-120, 32}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 6}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TRooSet "Room/zone temperature setpoint [K]. Compared with TRoo to determine SAT reset level." annotation(
        Placement(transformation(origin = {-122, -22}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, -58}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TSup "Supply air temperature measurement [K] (downstream of coil/supply duct sensor). Controlled variable for the PI loop." annotation(
        Placement(transformation(origin = {-120, -88}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-120, 68}, extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn "System enable (true = HVAC allowed to operate). If false, valve and pump are forced OFF." annotation(
        Placement(transformation(origin = {-116, 184}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-80, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Interfaces.BooleanInput winOpe "Window open / natural ventilation flag (true = window open). If true, valve and pump are forced OFF." annotation(
        Placement(transformation(origin = {-116, 146}, extent = {{-20, -20}, {20, 20}}), iconTransformation(origin = {-32, -120}, extent = {{-20, 20}, {20, -20}}, rotation = 90)));
      // Outputs
      Modelica.Blocks.Interfaces.RealOutput yValChi "Cooling coil valve command (0..1). When enabled, equals max(PI, ValMinOn); when disabled, equals ValOff." annotation(
        Placement(transformation(origin = {314, 168}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, 44}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput yPumChi "Hydronic pump command (0/1). ON when system is enabled AND windows are closed." annotation(
        Placement(transformation(origin = {314, 224}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -42}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.RealOutput TSupSet
        "Calculated SAT setpoint [K]. Reset from TSupSetMax toward TSupSetFan as room temperature error increases."                                                                annotation(
        Placement(transformation(origin={316,6},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -86}, extent = {{-10, -10}, {10, 10}})));
      // Parameters
      parameter Modelica.Units.SI.TemperatureDifference dTDb = 0.2 "SAT reset deadband [K]. No SAT reset until (TRoo-TRooSet) exceeds dTDb, which prevents hunting around setpoint.";
      parameter Modelica.Units.SI.TemperatureDifference dTMax = 2 "Room temperature error [K] that drives SAT fully to TSupSetFan. Larger value makes SAT reset less aggressive.";
      parameter Modelica.Units.SI.Temperature TSupSetMax = 273.15 + 20 "Max SAT [K] used when there is little/no cooling demand (typically warmer to save energy).";
      parameter Modelica.Units.SI.Temperature TSupSetMin = 273.15 + 13 "Absolute minimum SAT limit [K]. Not normally used by supervisory SAT reset.";
      parameter Modelica.Units.SI.TemperatureDifference dTSupFan = 2 "Offset above TSupSetMin used as the effective SAT level for fan-stage operation.";
      parameter Real kVal = 0.05 "Valve PI proportional gain. Higher kVal increases responsiveness but can increase oscillation.";
      parameter Modelica.Units.SI.Time TiVal = 300 "Valve PI integral time [s]. Smaller TiVal integrates faster (removes offset faster) but may cause instability.";
      // ---------------------------------------------------------------------------
      // Control logic blocks
      // ---------------------------------------------------------------------------
      // Compute room temperature error: e = TRoo - TRooSet
      Modelica.Blocks.Math.Add errTRoo(k1 = +1, k2 = -1) "Room temperature error [K]. Positive means room is warmer than setpoint (cooling demand)." annotation(
        Placement(transformation(origin = {-60, -2}, extent = {{-10, -10}, {10, 10}})));
      // Apply deadband before SAT reset: (e - dTDb)
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conDTDb(k = dTDb) "Deadband constant [K] used to delay SAT reset until cooling demand is meaningful." annotation(
        Placement(transformation(origin = {-60, -38}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Add errDb(k1 = +1, k2 = -1) "Deadbanded error: (TRoo-TRooSet) - dTDb. Negative/near-zero values imply little demand." annotation(
        Placement(transformation(origin = {-16, -8}, extent = {{-10, -10}, {10, 10}})));
      // Normalize demand to a 0..1 reset signal: u = ((e-dTDb)/dTMax), clipped to [0,1]
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conInvDTMax(k = 1/dTMax) "Inverse of dTMax used to normalize room error into a 0..1 reset signal." annotation(
        Placement(transformation(origin = {-16, -58}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Product norm "Normalized reset signal u = ((e - dTDb) * (1/dTMax))." annotation(
        Placement(transformation(origin = {26, -14}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
      Modelica.Blocks.Nonlinear.Limiter limRes(uMax = 1, uMin = 0) "Limiter to keep reset signal within [0,1]. u=0 -> neutral SAT, u=1 -> minimum SAT." annotation(
        Placement(transformation(origin = {64, -14}, extent = {{-10, -10}, {10, 10}})));
      // Build SAT setpoint from max and minimum SAT:
      // SATSP = TSupSetMax + u*(TSupSetMin - TSupSetMax)
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetFan(k=TSupSetMin +
            dTSupFan)
        "Effective minimum SAT target used by normal reset and fan-stage operation [K]."                          annotation(
        Placement(transformation(origin = {24, 82}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conTSupSetMax(k=TSupSetMax)
        "Max SAT constant [K]."                                                                                   annotation(
        Placement(transformation(origin = {26, 40}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Add dTSupSet(k1 = +1, k2 = -1)
        "SAT reset span: TSupSetFan - TSupSetMax."                                                                                                        annotation(
        Placement(transformation(origin = {68, 56}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Product mul
        "Scaled reset span: u*(TSupSetFan - TSupSetMax)."                                annotation(
        Placement(transformation(origin={108,22},    extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      Modelica.Blocks.Math.Add TSupSetCal(k1 = +1, k2 = +1)
        "Computed SAT setpoint: TSupSetMax + u*(TSupSetFan - TSupSetMax)."                                                     annotation(
        Placement(transformation(origin={146,34},    extent = {{-10, -10}, {10, 10}})));
      // PI controller: tracks SATSP by modulating cooling valve
      Buildings.Controls.OBC.CDL.Reals.PID pidVal(controllerType = Buildings.Controls.OBC.CDL.Types.SimpleController.PI, k = kVal, Ti = TiVal, reverseActing = false, yMax = 1, yMin = 0)
        "PI loop controlling valve (y) to drive measured TSA (u_m) toward SATSP (u_s)."                                                                                                                         annotation(
        Placement(transformation(origin = {204, 34}, extent = {{-10, -10}, {10, 10}}, rotation = -0)));
      // System permissive logic:
      // enable = sysOn AND (NOT winOpen)
      Modelica.Blocks.Logical.Not notWinOpe "Logical NOT of winOpen. If winOpen = true, then notWin = false; If winOpen = false, then notWin = true." annotation(
        Placement(transformation(origin = {-56, 146}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.And sysPerm "Enable signal: sysOn AND notWin. Used to enable pump and valve operation." annotation(
        Placement(transformation(origin = {12, 168}, extent = {{-10, -10}, {10, 10}})));
      // Valve handling when enabled:
      // yVal_on = max(conPID.y, ValMinOn) to avoid sticking and to ensure some minimum flow
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conValMinOn(k=0.005)  "Minimum valve opening when enabled (0..1). Prevents valve sticking and improves numerical robustness." annotation(
        Placement(transformation(origin = {204, 80}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Math.Max maxVal "Selects the larger of PI output and ValMinOn." annotation(
        Placement(transformation(origin = {244, 58}, extent = {{-10, -10}, {10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conValOff(k=0.0)   "Valve command when disabled (normally 0)." annotation(
        Placement(transformation(origin = {204, 194}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Logical.Switch swiVal "Valve enable switch: if andSys=true -> output maxVal; else -> ValOff." annotation(
        Placement(transformation(origin = {274, 168}, extent = {{-10, 10}, {10, -10}}, rotation = -0)));
      Buildings.Controls.OBC.CDL.Conversions.BooleanToReal pumCmd(realTrue=0.8,
          realFalse=0.0)                                                                           "Converts enable boolean to pump command (1=ON, 0=OFF)." annotation(
        Placement(transformation(origin = {118, 224}, extent = {{-10, -10}, {10, 10}})));
      Modelica.Blocks.Interfaces.BooleanInput fanStage
        "If true, force TSupSet to TSupSetFan during second-stage fan cooling."
        annotation (Placement(transformation(
            extent={{-20,-20},{20,20}},
            rotation=90,
            origin={76,-120}), iconTransformation(
            extent={{-20,-20},{20,20}},
            rotation=90,
            origin={76,-120})));
      Modelica.Blocks.Logical.Switch swiTSupSet
        "If fanStage=true, force TSupSetFan; else use normal TSupSetCal"
        annotation (Placement(transformation(extent={{146,114},{166,134}})));
    equation
      connect(TRoo, errTRoo.u1) annotation(
        Line(points = {{-120, 32}, {-72, 32}, {-72, 4}}, color = {0, 0, 127}));
      connect(TRooSet, errTRoo.u2) annotation(
        Line(points = {{-122, -22}, {-72, -22}, {-72, -8}}, color = {0, 0, 127}));
      connect(errTRoo.y, errDb.u1) annotation(
        Line(points={{-49,-2},{-28,-2}},      color = {0, 0, 127}));
      connect(conDTDb.y, errDb.u2) annotation(
        Line(points = {{-48, -38}, {-28, -38}, {-28, -14}}, color = {0, 0, 127}));
      connect(errDb.y, norm.u1) annotation(
        Line(points={{-5,-8},{14,-8}},      color = {0, 0, 127}));
      connect(conInvDTMax.y, norm.u2) annotation(
        Line(points = {{-4, -58}, {14, -58}, {14, -20}}, color = {0, 0, 127}));
      connect(norm.y, limRes.u) annotation(
        Line(points={{37,-14},{52,-14}},      color = {0, 0, 127}));
      connect(conTSupSetFan.y, dTSupSet.u1) annotation(
        Line(points = {{36, 82}, {56, 82}, {56, 62}}, color = {0, 0, 127}));
      connect(conTSupSetMax.y, dTSupSet.u2) annotation(
        Line(points = {{38, 40}, {56, 40}, {56, 50}}, color = {0, 0, 127}));
      connect(limRes.y, mul.u2) annotation(
        Line(points={{75,-14},{86,-14},{86,16},{96,16}},  color = {0, 0, 127}));
      connect(dTSupSet.y, mul.u1) annotation(
        Line(points={{79,56},{86,56},{86,28},{96,28}},  color = {0, 0, 127}));
      connect(conTSupSetMax.y, TSupSetCal.u1) annotation(
        Line(points={{38,40},{134,40}},      color = {0, 0, 127}));
      connect(mul.y, TSupSetCal.u2) annotation(
        Line(points={{119,22},{124,22},{124,28},{134,28}},
                                                         color = {0, 0, 127}));
      connect(TSup, pidVal.u_m) annotation(
        Line(points = {{-120, -88}, {204, -88}, {204, 22}}, color = {0, 0, 127}));
      connect(sysOn, sysPerm.u1) annotation(
        Line(points = {{-116, 184}, {0, 184}, {0, 168}}, color = {255, 0, 255}));
      connect(winOpe, notWinOpe.u) annotation(
        Line(points = {{-116, 146}, {-68, 146}}, color = {255, 0, 255}));
      connect(notWinOpe.y, sysPerm.u2) annotation(
        Line(points={{-45,146},{0,146},{0,160}},        color = {255, 0, 255}));
      connect(pidVal.y, maxVal.u2) annotation(
        Line(points = {{216, 34}, {232, 34}, {232, 52}}, color = {0, 0, 127}));
      connect(conValMinOn.y, maxVal.u1) annotation(
        Line(points = {{216, 80}, {232, 80}, {232, 64}}, color = {0, 0, 127}));
      connect(maxVal.y, swiVal.u1) annotation(
        Line(points={{255,58},{262,58},{262,160}},        color = {0, 0, 127}));
      connect(conValOff.y, swiVal.u3) annotation(
        Line(points = {{216, 194}, {262, 194}, {262, 176}}, color = {0, 0, 127}));
      connect(swiVal.y, yValChi) annotation(
        Line(points={{285,168},{314,168}},      color = {0, 0, 127}));
      connect(sysPerm.y, pumCmd.u) annotation(
        Line(points={{23,168},{106,168},{106,224}},        color = {255, 0, 255}));
      connect(pumCmd.y, yPumChi) annotation(
        Line(points = {{130, 224}, {314, 224}}, color = {0, 0, 127}));
      connect(sysPerm.y, swiVal.u2) annotation(
        Line(points={{23,168},{262,168}},      color = {255, 0, 255}));
      connect(conTSupSetFan.y, swiTSupSet.u1) annotation (Line(points={{36,82},{38,82},
              {38,132},{144,132}}, color={0,0,127}));
      connect(fanStage, swiTSupSet.u2) annotation (Line(points={{76,-120},{76,124},{
              144,124}}, color={255,0,255}));
      connect(TSupSetCal.y, swiTSupSet.u3) annotation (Line(points={{157,34},{162,34},
              {162,108},{144,108},{144,116}}, color={0,0,127}));
      connect(swiTSupSet.y, pidVal.u_s) annotation (Line(points={{167,124},{182,124},
              {182,34},{192,34}}, color={0,0,127}));
      connect(swiTSupSet.y, TSupSet) annotation (Line(points={{167,124},{182,124},{182,
              6},{316,6}}, color={0,0,127}));

      annotation(
        Diagram(coordinateSystem(extent = {{-140, 240}, {320, -120}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {0, 48}, rotation = 180, extent = {{-98, 50}, {98, -50}}, imageSource = "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gs8fMyE0YJrbZ7HzWmFpUGZvwX1V2oilIIT88RJGA1zfjBvSG0uDsfB13FOlAixFYeSPlVAa8DFuUqn0QAivB+tPdz395w9Y6xBK/jgJpwEf4TZnLTuGtblaeQXu46y3s38QFU7+GAmnAfkHcaOzSv+vD1bnYkE/3ME5N+zDaqdw8sdISA04PBO3Omf+xIFYruu+TU1w9XPWejkVIaT88XEBxsvegAuwIp19HXCzKrbX8PB/M7thn7u89j9lZz7WpxNW/tgozhrP0aJirEir0PWZYIVuz2T/85xF/rTXcNWqrsH69ELLHxe9MN5bWPEWVnj9dLeX2/sBp2xuOgI38KP+O64v/SqU/hI3cBFi/njYhvFGlqcWlI/Eim2pBe62ubw7d8beA9pXj+06kPnCnxOe30gNM38sHMN4Cno3Bm9X3l/ILcp8Nyn1r2c0ngwc7tsV1wEbVuI2rkLNHwf3YDzV5HjV2487n2bfU/X2zF7NeoZ+yzXL38etMlnwTIeWuAZ63ccnj+Hmj4HyVZhPnazy/KzwJN6qVsFjZEYvu78hcFbR2Esewe3Su7ngXy6fNFXVzs+7jSHnj4E0L9e++bTyxk+/wduU6pC6fTYXtcUF0llye8ETGd8gennlptFLcKt0GkzDTTMLO794T2HAiqdn+099v8OO/XvxFqXUU7hCFu1b4wpuhtwxcUyny+Ajw56XHdt21c+HYK2b62qnbp5V6Pmlq5/+f+j2tWu347+d0tbPA+wpA10/q02vQbexB0872XWZz8s853l59y9F+PmlW4sRM1uL23uwbT6uEo75y3HPHkSQX7Z/Y8TM/o3be9FmPC4TgtI9Kc/fvYoiv2wenqifcxC39qi35lf2eHfvQtynR5Hkl6y2h5dWlZr5fY51VvkPQ/07sKqG9sUn0eSXzPGRqLtcPgq9c2fGDwdyUTJvMO7Nh4jyyzXY84usIbn0OS/v29twwWB0r4Z78iWy/GK134BJ09vQHrf0q3eGE0U0lZ5cgXvxK7r8Um319OBcuhW30/DqGh9/crO7a4/Ht5EzijC/UJ6+VmMibqXn06M+391x98/pu3F1PVHml2mT66nVlUo24Tba+vwn48k8Xi37T8aPD3yJNL9Ij2b57L7sUdwiJyuOPoh78OfBo6/gmjmJOL9AjyzDzFUtC+JPbYr8lTu/h3vxqqzdVE+nfPoRdX55Vhe7XNirVOfi1VgdhGFPd/gEd5XdGx8sPowrBSH6/OIc6VeE0SsU9TuClcFpuLGdjycEr+35sgWuEBwT+YX5+kAdjF/nwNdYFbTdffvVaoD7RQ1enPePgJ7zuzOTX5TCap9tPvuMuGTzZ9VyPoHfoynH+hffMSDNK8QTrQ8++07j87A+JMbyS5J/5Nutn3++9dsjgT/Tyqqw55E55zeevPydH7009ydPN3/l5i7rtT/l0WYwPxERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER6fh/H7w6my0mDdAAAAAASUVORK5CYII="), Bitmap(origin = {0, -48}, rotation = 180, extent = {{-98, 52}, {98, -52}}, imageSource = "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")}));
    end HydronicTSupPICtrl_old;

    model FilteredPowerMeter
      // remove the AC off power, as AC off fan is used to help SAT state evolve.

      parameter Modelica.Units.SI.SpecificHeatCapacity cpWat = 4180 "Water cp (J/kg.K)";
      parameter Real COPCoo = 2.5 "Assumed COP of ASHP";
      Modelica.Blocks.Math.Add dTWat(k1 = -1, k2 = +1) "Tret - Tsup" annotation(
        Placement(transformation(origin={106,-24},  extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Gain cpGain(k = cpWat) annotation(
        Placement(transformation(origin={62,-24},   extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Product mCpDT annotation(
        Placement(transformation(origin={18,-30},    extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conZer(k = 0) annotation(
        Placement(transformation(origin={18,18},     extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Max qCoo annotation(
        Placement(transformation(origin={-26,-24},   extent = {{10, -10}, {-10, 10}})));
      Buildings.Controls.OBC.CDL.Reals.Sources.Constant conCOP(k = COPCoo) annotation(
        Placement(transformation(origin={-26,-62},   extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Math.Division divCOP annotation(
        Placement(transformation(origin={-68,-30},    extent = {{10, -10}, {-10, 10}})));
      Modelica.Blocks.Interfaces.RealInput TWatRet "CHW return temp (K)" annotation(
        Placement(transformation(origin={158,-48},  extent = {{20, -20}, {-20, 20}}), iconTransformation(origin={-120,60},   extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput TWatSup "CHW supply temp (K)" annotation(
        Placement(transformation(origin={158,-12},   extent = {{20, -20}, {-20, 20}}), iconTransformation(origin={-120,100},   extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealInput mChiWat "Water mass flow (kg/s)" annotation(
        Placement(transformation(origin={158,-88},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin={-120,20},     extent = {{-20, -20}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealOutput PASHP "ASHP electric power (W)"
        annotation (Placement(transformation(origin={-134,-30},extent={{10,-10},
                {-10,10}}), iconTransformation(origin={110,90},extent={{-10,-10},
                {10,10}})));
      Modelica.Blocks.Interfaces.RealInput PPump annotation (Placement(
            transformation(origin={158,42}, extent={{20,-20},{-20,20}}),
            iconTransformation(origin={-120,-20}, extent={{-20,-20},{20,20}})));
      Modelica.Blocks.Interfaces.RealOutput PPumChi annotation (Placement(
            transformation(origin={-138,42}, extent={{10,-10},{-10,10}}),
            iconTransformation(origin={110,30},extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Interfaces.RealInput PSupFanAll annotation (Placement(
            transformation(origin={158,126}, extent={{20,-20},{-20,20}}),
            iconTransformation(origin={-120,-60}, extent={{-20,-20},{20,20}})));
      Modelica.Blocks.Interfaces.BooleanInput sysOn annotation(
        Placement(transformation(origin={158,80},       extent={{20,-20},{-20,
                20}}),                                                                    iconTransformation(origin={-80,-120},    extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      Modelica.Blocks.Math.BooleanToReal booleanToReal(realTrue=1.0, realFalse=0.0)
        annotation (Placement(transformation(extent={{108,68},{82,94}})));
      Modelica.Blocks.Interfaces.RealOutput PSupFan annotation (Placement(
            transformation(origin={-126,120}, extent={{10,-10},{-10,10}}),
            iconTransformation(origin={110,-30},
                                               extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Math.Product proSupFan
        annotation (Placement(transformation(extent={{-76,112},{-94,130}})));
      Modelica.Blocks.Interfaces.RealOutput PRetFan annotation (Placement(
            transformation(origin={-128,152}, extent={{10,-10},{-10,10}}),
            iconTransformation(origin={110,-90},
                                               extent={{-10,-10},{10,10}})));
      Modelica.Blocks.Math.Product proRetFan
        annotation (Placement(transformation(extent={{-72,142},{-90,160}})));
      Modelica.Blocks.Interfaces.RealInput PRetFanAll annotation (Placement(
            transformation(origin={160,160}, extent={{20,-20},{-20,20}}),
            iconTransformation(origin={-120,-100},extent={{-20,-20},{20,20}})));
    equation
      connect(dTWat.y, cpGain.u) annotation(
        Line(points={{95,-24},{74,-24}},    color = {0, 0, 127}));
      connect(cpGain.y, mCpDT.u1) annotation(
        Line(points={{51,-24},{30,-24}},    color = {0, 0, 127}));
      connect(conZer.y, qCoo.u1) annotation(
        Line(points={{6,18},{-14,18},{-14,-18}},         color = {0, 0, 127}));
      connect(mCpDT.y, qCoo.u2) annotation(
        Line(points={{7,-30},{-14,-30}},      color = {0, 0, 127}));
      connect(qCoo.y, divCOP.u1) annotation(
        Line(points={{-37,-24},{-56,-24}},     color = {0, 0, 127}));
      connect(conCOP.y, divCOP.u2) annotation(
        Line(points={{-38,-62},{-56,-62},{-56,-36}},       color = {0, 0, 127}));
      connect(TWatSup, dTWat.u1) annotation(
        Line(points={{158,-12},{118,-12},{118,-18}},   color = {0, 0, 127}));
      connect(TWatRet, dTWat.u2) annotation(
        Line(points={{158,-48},{118,-48},{118,-30}}, color = {0, 0, 127}));
      connect(mChiWat, mCpDT.u2) annotation(
        Line(points={{158,-88},{30,-88},{30,-36}},         color = {0, 0, 127}));
      connect(sysOn, booleanToReal.u) annotation (Line(points={{158,80},{118,80},{118,
              81},{110.6,81}}, color={255,0,255}));
      connect(booleanToReal.y, proSupFan.u2) annotation (Line(points={{80.7,81},{50,
              81},{50,115.6},{-74.2,115.6}}, color={162,29,33}));
      connect(PSupFanAll, proSupFan.u1) annotation (Line(points={{158,126},{-70,126},
              {-70,126.4},{-74.2,126.4}}, color={0,0,127}));
      connect(proSupFan.y, PSupFan) annotation (Line(points={{-94.9,121},{-112,121},
              {-112,120},{-126,120}}, color={0,0,127}));
      connect(booleanToReal.y, proRetFan.u2) annotation (Line(points={{80.7,81},{50,
              81},{50,145.6},{-70.2,145.6}}, color={162,29,33}));
      connect(PRetFanAll, proRetFan.u1) annotation (Line(points={{160,160},{86,160},
              {86,156},{-70.2,156},{-70.2,156.4}}, color={0,0,127}));
      connect(proRetFan.y, PRetFan) annotation (Line(points={{-90.9,151},{-109.45,151},
              {-109.45,152},{-128,152}}, color={0,0,127}));
      connect(PPump, PPumChi)
        annotation (Line(points={{158,42},{-138,42}}, color={0,0,127}));
      connect(divCOP.y, PASHP)
        annotation (Line(points={{-79,-30},{-134,-30}}, color={0,0,127}));
      annotation(
        Diagram(coordinateSystem(extent = {{-160, 100}, {140, -60}})),
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Bitmap(origin = {-4, -2}, extent = {{72, -66}, {-72, 66}}, imageSource = "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")}));
    end FilteredPowerMeter;
  end BaseClasses;

  model HCDLabPMVPIEval
    // FMU
    // inputs
    Modelica.Blocks.Interfaces.RealInput TRooSet "Zone temperature setpoint [K]" annotation(
      Placement(transformation(origin={300,224},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, -20}, extent = {{-20, -20}, {20, 20}})));
    Modelica.Blocks.Interfaces.RealInput CO2Set "CO2 setpoint [ppm]" annotation(
      Placement(transformation(origin={300,192},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 20}, extent = {{-20, -20}, {20, 20}})));
    Modelica.Blocks.Interfaces.RealInput uWinOpe
      "Window command: 0=closed, >0.1=open"                                            annotation(
      Placement(transformation(origin={300,110},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 100}, extent = {{-20, -20}, {20, 20}})));
    Modelica.Blocks.Interfaces.RealInput heaFra
      "Internal heat gain fraction (0..1)" annotation (Placement(transformation(
            origin={-378,-216}, extent={{-20,-20},{20,20}}), iconTransformation(
            origin={-120,-60}, extent={{-20,-20},{20,20}})));
    Modelica.Blocks.Interfaces.RealInput occFra "Occupancy fraction (0..1)"
      annotation (Placement(transformation(origin={-378,-180}, extent={{-20,-20},
              {20,20}}), iconTransformation(origin={-120,-100}, extent={{-20,-20},
              {20,20}})));
    // outputs
    Modelica.Blocks.Interfaces.RealOutput yValChi "Cooling valve actual position (0..1)" annotation(
      Placement(transformation(origin={-370,96},     extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 70}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PPumChi "Pump electrical power [W]" annotation(
      Placement(transformation(origin={-370,224},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -90}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput yDamOut "Outdoor-air damper actual position (0..1)" annotation(
      Placement(transformation(origin={-370,136},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -70}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PFanSup "Supply fan electrical power [W]" annotation(
      Placement(transformation(origin={-370,206},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -50}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput yFanSup "Supply fan actual speed (0..1)" annotation(
      Placement(transformation(origin={-370,114},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -30}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput yFanRet "Return fan actual speed (0..1)" annotation(
      Placement(transformation(origin={-370,78},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -10}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PFanRet "Return fan electrical power [W]" annotation(
      Placement(transformation(origin={-370,192},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 10}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput TRoo "Zone air temperature [K]" annotation(
      Placement(transformation(origin={-370,62},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 30}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput CO2Roo "Zone CO2 concentration [ppm]" annotation(
      Placement(transformation(origin={-370,46},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 50}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PASHP annotation(
      Placement(transformation(origin={-370,242},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -90}, extent = {{-10, -10}, {10, 10}})));
    //
    replaceable package MediumA = Buildings.Media.Air(extraPropertiesNames = {"CO2"}) "Medium for air";
    replaceable package MediumW = Buildings.Media.Water "Medium for water";
    parameter Modelica.Units.SI.Length xIntMass = 0.01481324 "Effective thickness of internal mass layer (m) (calibrated)";
    parameter Modelica.Units.SI.Area AIntMass(min = 0) = 2*AFlo "Effective internal mass area (m2)";
    parameter Real nOccMax = 10 "Max number of occupants";
    parameter Real wCorOut(min = 0, max = 1) = 0.7 "Corridor temperature weight on outdoor";
    parameter Modelica.Units.SI.MassFlowRate mFlowNominal = 1;
    parameter Modelica.Units.SI.Height hRoo = 2.6 "Room height";
    parameter Modelica.Units.SI.Area AFlo = 81.76 "Floor area";
    parameter Modelica.Units.SI.Area ACeil = 81.76 "Ceiling area";
    parameter Modelica.Units.SI.Volume VRoo = 221.559 "Room volume";
    parameter Modelica.Units.SI.Length wExtSou = 7.3 "South exterior wall width";
    parameter Modelica.Units.SI.Length wIntNor = 7.3 "North interior wall width";
    parameter Modelica.Units.SI.Length wIntWes = 11.2 "West interior wall width";
    parameter Modelica.Units.SI.Length wIntEas = 11.2 "East interior wall width";
    parameter Real winWalRat(min = 0.01, max = 0.99) = 0.95 "Window to wall ratio for exterior walls";
    parameter Modelica.Units.SI.Length hWin = 2.6 "Height of windows (south)";
    // fixed neighbor temps (Kelvin)
    parameter Modelica.Units.SI.Temperature TWes = 300.15;
    parameter Modelica.Units.SI.Temperature TEas = 300.15;
    parameter Modelica.Units.SI.Temperature TFlo = 300.15;
    parameter Modelica.Units.SI.Temperature TCei = 300.15;
    ///////////////////////////////Materials\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matCon(x = 0.4, k = 1.311, c = 836, nStaRef = 5) "Concrete" annotation(
      Placement(transformation(origin={-170,304},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matAirGapFlo(c = 1006, d = 1.2, k = 0.026, nStaRef = 1, x = 0.112) "Air cavity (conduction-only approximation)" annotation(
      Placement(transformation(origin={-138,304},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matCemBoa(c = 837, d = 1922, k = 0.597, nStaRef = 1, x = 0.032) "Cement board (Cementitious fill)" annotation(
      Placement(transformation(origin={-106,304},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matCar(x = 0.006, k = 0.06, c = 1360, nStaRef = 1, d = 186) "Carpet" annotation(
      Placement(transformation(origin={-74,304},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matConWal(c = 836, k = 1.311, nStaRef = 2, x = 0.15) "Concrete for west, east, and south walls" annotation(
      Placement(transformation(origin={-106,280},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matConWalNor(c = 836, k = 1.311, nStaRef = 2, x = 0.26103384) "Concrete for north wall (window and door negleted), calibrate x" annotation(
      Placement(transformation(origin={-74,280},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matAirGapCei(c = 1006, d = 1.2, k = 0.026, nStaRef = 1, x = 0.525) annotation(
      Placement(transformation(origin={-170,280},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.GypsumBoard matGypBoa(x = 0.01) annotation(
      Placement(transformation(origin={-138,280},    extent = {{-10, -10}, {10, 10}})));
    ///////////////////////////OpaqueConstructions\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conExtWalS(final nLay = 1, material = {matConWal}) "South Exterior construction" annotation(
      Placement(transformation(origin={-12,304},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntWalN(final nLay = 1, material = {matConWalNor}) "North Interior construction (facing corridor)" annotation(
      Placement(transformation(origin={18,304},      extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntWalW(final nLay = 1, material = {matConWal}) "West Interior wall construction" annotation(
      Placement(transformation(origin={48,304},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntWalE(final nLay = 1, material = {matConWal}) "East Interior wall construction" annotation(
      Placement(transformation(origin={48,280},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntFlo(final nLay = 4, material = {matCon, matAirGapFlo, matCemBoa, matCar}) "Floor construction" annotation(
      Placement(transformation(origin={-12,280},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntCeil(final nLay = 3, material = {matCon, matAirGapCei, matGypBoa}) "Ceiling construction" annotation(
      Placement(transformation(origin={18,280},      extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matIntMass(c = 836, k = 1.311, nStaRef = 2, x = xIntMass) annotation(
      Placement(transformation(origin={78,306},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntMass(material = {matIntMass}, final nLay = 1) annotation(
      Placement(transformation(origin={78,280},     extent = {{-10, -10}, {10, 10}})));
    //////////////////////////////glazing system\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Data.GlazingSystems.DoubleClearAir13Clear glaSysS(UFra = 2, shade = Buildings.HeatTransfer.Data.Shades.Gray(), haveInteriorShade = false, haveExteriorShade = false) "Data record for the south glazing system" annotation(
      Placement(transformation(origin={-42,304},     extent = {{-10, -10}, {10, 10}})));
    ////////////////////////////////zone\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Types.InteriorConvection intConMod = Buildings.HeatTransfer.Types.InteriorConvection.Temperature "Convective heat transfer model for room-facing surfaces of opaque constructions";
    parameter Boolean sampleModel = false "Set to true to time-sample the model, which can give shorter simulation time if there is already time sampling in the system model" annotation(
      Evaluate = true,
      Dialog(tab = "Experimental (may be changed in future releases)"));
    Buildings.HeatTransfer.Sources.FixedTemperature westTemBnd(T = TWes) annotation(
      Placement(transformation(origin = {170, -90}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.FixedTemperature eastTemBnd(T = TEas) annotation(
      Placement(transformation(origin = {170, -126}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.FixedTemperature floorTemBnd(T = TFlo) annotation(
      Placement(transformation(origin = {170, -160}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.FixedTemperature ceilTemBnd(T = TCei) annotation(
      Placement(transformation(origin = {170, -194}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.PrescribedTemperature norTemBnd annotation(
      Placement(transformation(origin = {-16, -232}, extent = {{-10, -10}, {10, 10}})));
    /// zone \\\
    Buildings.ThermalZones.Detailed.MixedAir zon(redeclare package Medium = MediumA, AFlo = AFlo, hRoo = hRoo, use_C_flow = true, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC), nConExt = 0,  // >>>  Exterior with windows <<<
    nConExtWin = 1, datConExtWin(layers = {conExtWalS}, A = {wExtSou*hRoo}, glaSys = {glaSysS}, wWin = {winWalRat/hWin*wExtSou*hRoo}, each hWin = hWin, fFra = {0.2}, til = {Buildings.Types.Tilt.Wall}, azi = {Buildings.Types.Azimuth.S}),  // >>> Parallel constructions: internal masses <<<
    final nConPar = 1, datConPar(layers = {conIntMass}, A = {AIntMass}, til = {Buildings.Types.Tilt.Wall}, azi = {Buildings.Types.Azimuth.S}),  // >>> explicitly constructed shared walls <<<
    final nConBou = 0,  // >>> passive boundary surfaces with external heat ports <<<
    final nSurBou = 5, surBou(A = {wIntWes*hRoo, wIntEas*hRoo, AFlo, ACeil, wIntNor*hRoo}, til = {Buildings.Types.Tilt.Wall, Buildings.Types.Tilt.Wall, Buildings.Types.Tilt.Floor, Buildings.Types.Tilt.Ceiling, Buildings.Types.Tilt.Wall}, each absIR = 0.9, each absSol = 0.9), nPorts = 5, intConMod = intConMod, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, final sampleModel = sampleModel) annotation(
      Placement(transformation(origin = {62, -50}, extent = {{-20, -20}, {20, 20}})));
    /// interior walls \\\
    Buildings.HeatTransfer.Conduction.MultiLayer walWest(A = wIntWes*hRoo, layers(nLay = 1, material = {matConWal}), T_a_start = TWes, T_b_start = TWes) annotation(
      Placement(transformation(origin = {114, -90}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer walEast(A = wIntEas*hRoo, T_a_start = TEas, T_b_start = TEas, layers(nLay = 1, material = {matConWal})) annotation(
      Placement(transformation(origin = {114, -126}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer floSlab(A = AFlo, T_a_start = TFlo, T_b_start = TFlo, layers(nLay = 4, material = {matCon, matAirGapFlo, matCemBoa, matCar})) annotation(
      Placement(transformation(origin = {116, -160}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer ceiSlab(A = ACeil, T_a_start = TCei, T_b_start = TCei, layers(material = {matCon, matAirGapCei, matGypBoa}, nLay = 3)) annotation(
      Placement(transformation(origin = {116, -194}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer walNorth(A = wIntNor*hRoo, T_a_start = 297.15, T_b_start = 297.15, layers(material = {matConWalNor}, nLay = 1), steadyStateInitial = false) annotation(
      Placement(transformation(origin = {28, -232}, extent = {{10, -10}, {-10, 10}})));
    // corridor boundary temperature model
    Modelica.Blocks.Continuous.FirstOrder zonTemLag(T = 600) annotation(
      Placement(transformation(origin = {30, -266}, extent = {{10, -10}, {-10, 10}})));
    Modelica.Blocks.Math.Gain gaiZonTem(k = 1 - wCorOut) "Zone temperature weight" annotation(
      Placement(transformation(origin = {-18, -266}, extent = {{10, -10}, {-10, 10}})));
    Modelica.Blocks.Math.Gain gaiOutTem(k = wCorOut) annotation(
      Placement(transformation(origin = {-200, -226}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Add corTemMix annotation(
      Placement(transformation(origin = {-110, -232}, extent = {{-10, -10}, {10, 10}})));
    // heat and co2 gain
    Modelica.Blocks.Sources.RealExpression co2GenOcc(y=occFra*nOccMax*9.6e-6)
      "0.0052 L/s-person with co2 density about 1.84 kg/m3"
                   annotation (Placement(transformation(origin={-316,-168},
            extent={{-10,-10},{10,10}})));
    MMV_clean.BaseClasses.InternalGains3 intGains(
      qHea_Wm2=30.24,
      qMis_Wm2=3.2116997,
      qOcc_nominal_Wm2=14.5548) annotation (Placement(transformation(origin={-202,
              -196}, extent={{-14,-14},{14,14}})));
    Modelica.Blocks.Sources.Constant misGainFra(k = 1) annotation(
      Placement(transformation(origin = {-258, -196}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Routing.Multiplex3 gainMux annotation(
      Placement(transformation(origin = {-110, -196}, extent = {{-10, -10}, {10, 10}})));
    ////////////////////////////////HVAC\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    Buildings.Fluid.Movers.SpeedControlled_y pumChi(redeclare package Medium = MediumW, addPowerToMedium = false, energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyState, inputType = Buildings.Fluid.Types.InputType.Continuous, redeclare MMV_clean.BaseClasses.Pump_per
                                                                                                                                                                                                        per, use_inputFilter = true, riseTime = 600,
      allowFlowReversal=false)                                                                                                                                                                                                         annotation(
      Placement(transformation(origin = {-84, 68}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage valChi(redeclare package Medium = MediumW, m_flow_nominal = 0.5, dpValve_nominal = 2000, dpFixed_nominal = 1000, use_inputFilter = true,
      riseTime=180,
      allowFlowReversal=false)                                                                                                                                                                                                         annotation(
      Placement(transformation(origin = {-32, 112}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.HeatExchangers.WetCoilEffectivenessNTU coiCoo(redeclare package Medium2 = MediumA, redeclare package Medium1 = MediumW, m1_flow_nominal = 3, m2_flow_nominal = 1, dp1_nominal = 1000, dp2_nominal = 0,
      energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
      UA_nominal=1300,                                                                                                                                                                                                        configuration = Buildings.Fluid.Types.HeatExchangerConfiguration.CounterFlow,
      allowFlowReversal1=false,
      allowFlowReversal2=false)                                                                                                                                                                                                        annotation(
      Placement(transformation(origin = {-58, 20}, extent = {{10, -10}, {-10, 10}})));
    Buildings.Fluid.Movers.SpeedControlled_y fanSup(redeclare package Medium = MediumA,
      energyDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial,                                                                                     redeclare MMV_clean.BaseClasses.FAN_per
                                                                                                                                                                                             per, inputType = Buildings.Fluid.Types.InputType.Continuous, addPowerToMedium = false, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC),
      allowFlowReversal=true,                                                                                                                                                                                                        m_flow(start = 1), dp(start = 10), C_nominal = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC), use_inputFilter = true, riseTime = 60) annotation(
      Placement(transformation(origin={-6,14},    extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Movers.SpeedControlled_y fanRet(redeclare package Medium = MediumA, addPowerToMedium = false,
      energyDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial,                                                                                                               inputType = Buildings.Fluid.Types.InputType.Continuous, redeclare MMV_clean.BaseClasses.FAN_per
                                                                                                                                                                                                        per, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC),
      allowFlowReversal=true,
      riseTime=60,                                                                                                                                                                                                        m_flow(start = 1), dp(start = 10), C_nominal = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC)) annotation(
      Placement(transformation(origin = {-152, -60}, extent = {{10, -10}, {-10, 10}})));
    Buildings.Fluid.Actuators.Dampers.Exponential damOut(redeclare package Medium = MediumA, dpDamper_nominal = 1473.57487105, m_flow_nominal = mFlowNominal, dpFixed_nominal = 138.64528868, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-186, 14}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
    Buildings.Fluid.FixedResistances.Junction mixJun(m_flow_nominal = {1, -2, 1}, dp_nominal = {2000, -500, 500}, redeclare package Medium = MediumA, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC), C_nominal = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC)) annotation(
      Placement(transformation(origin = {-162, 14}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.FixedResistances.PressureDrop resSup(redeclare package Medium = MediumA, m_flow_nominal = 1, dp_nominal = 262.62076974, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {60, -12}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.FixedResistances.PressureDrop resRet(redeclare package Medium = MediumA, dp_nominal = 223.38405591, m_flow_nominal = 1, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-88, -60}, extent = {{10, -10}, {-10, 10}})));
    BaseClasses.RoomLeakage roomLeak(redeclare package Medium = MediumA, VRoo = VRoo, s = 1, azi = 0, amb(C = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC))) annotation(
      Placement(transformation(origin = {-95, -147}, extent = {{-15, -15}, {15, 15}})));
    // operable window
    Buildings.Airflow.Multizone.DoorDiscretizedOperable winOpe(wOpe = 7.3/2, hOpe = 2.6, hA = hRoo/2, hB = hRoo/2, redeclare package Medium = MediumA, LClo = 0.005) annotation(
      Placement(transformation(origin = {-2, -96}, extent = {{10, -10}, {-10, 10}})));
    // sensors
    Buildings.Fluid.Sensors.TemperatureTwoPort senMixTem(redeclare package Medium = MediumA, m_flow_nominal = mFlowNominal, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-132, 14}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sensors.TemperatureTwoPort senSupTem(redeclare package Medium = MediumA, m_flow_nominal = mFlowNominal, allowFlowReversal = true) annotation(
      Placement(transformation(origin={48,14},    extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sensors.MassFlowRate senSupFlo(redeclare package Medium = MediumA, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-102, 14}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sensors.MassFlowRate senRetFlo(redeclare package Medium = MediumA, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {4, -60}, extent = {{10, -10}, {-10, 10}})));
    Buildings.Fluid.Sensors.MassFlowRate senOutFlo(redeclare package Medium = MediumA) annotation(
      Placement(transformation(origin = {-204, -18}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Buildings.Fluid.Sensors.MassFlowRate senMasFloValv(redeclare package Medium = MediumW, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-32, 70}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.Sensors.PPMTwoPort senRetCO2(redeclare package Medium = MediumA, m_flow_nominal = 1, allowFlowReversal = true, C_start = 400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM) annotation(
      Placement(transformation(origin = {-42, -60}, extent = {{10, -10}, {-10, 10}})));
    Modelica.Blocks.Sources.RealExpression zonCO2(y = zon.air.vol.C[1]*1e6*Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM/Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM) annotation(
      Placement(transformation(origin={-334,46},   extent = {{10, -10}, {-10, 10}}, rotation = -0)));
    Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor senRooTem annotation(
      Placement(transformation(origin = {98, -50}, extent = {{-10, -10}, {10, 10}})));

    // boundaries
    Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
      Placement(transformation(origin={-272,-84},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-88, 88}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sources.Outside ambAir(nPorts = 3, redeclare package Medium = MediumA, use_C_in = false, C = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC)) annotation(
      Placement(transformation(origin = {-352, 26}, extent = {{-10, -10}, {10, 10}})));
    Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(filNam=
          Modelica.Utilities.Files.loadResource(
          "modelica://Buildings/Resources/weatherdata/SGP_SG_Singapore-Changi.Intl.AP.486980_TMYx.2009-2023.mos"))                                                                                            annotation(
      Placement(transformation(origin={-317,-85},    extent={{-15,-15},{15,15}})));
    Buildings.Fluid.Sources.Boundary_pT chiWatSup(T = 282.15, redeclare package Medium = MediumW, nPorts = 1) annotation(
      Placement(transformation(origin = {-32, 180}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.Sources.Boundary_pT chiWatRet(redeclare package Medium = MediumW, nPorts = 1) annotation(
      Placement(transformation(origin = {-84, 180}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    ////////////////////////////////SP tracking\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  Buildings.Fluid.Sensors.TemperatureTwoPort senWatRetTem(redeclare package Medium = MediumW, m_flow_nominal = 3) annotation(
      Placement(transformation(origin = {-84, 122}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Buildings.Fluid.Sensors.TemperatureTwoPort senWatSupTem(redeclare package Medium = MediumW, m_flow_nominal = 3) annotation(
      Placement(transformation(origin = {-32, 144}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));

    Modelica.Blocks.Continuous.FirstOrder winCmdFil(k=1, T=120)
      annotation (Placement(transformation(extent={{234,-106},{216,-88}})));

    Modelica.Blocks.Math.RealToBoolean winOpeBool(threshold=0.1)
      annotation (Placement(transformation(extent={{178,102},{160,120}})));
    Modelica.Blocks.Math.RealToBoolean sysOnBool(threshold=0.1)
      annotation (Placement(transformation(extent={{180,140},{162,158}})));
    Modelica.Blocks.Interfaces.RealInput uSysOn
      "System command: 0=off, >0.1=on" annotation (Placement(transformation(
            origin={300,150}, extent={{20,-20},{-20,20}}), iconTransformation(
            origin={-120,100}, extent={{-20,-20},{20,20}})));
    Buildings.Utilities.Psychrometrics.Phi_pTX phi
      annotation (Placement(transformation(extent={{-314,258},{-340,282}})));
    Modelica.Blocks.Interfaces.RealOutput RhRoo "Zone relative humidity [0..1]"
      annotation (Placement(transformation(extent={{-360,260},{-380,280}})));
    Modelica.Blocks.Sources.RealExpression rooXw(y=zon.air.vol.X_w)
      annotation (Placement(transformation(extent={{-270,270},{-290,290}})));
    Modelica.Blocks.Sources.RealExpression rooPre(y=zon.ports[1].p)
      annotation (Placement(transformation(extent={{-270,250},{-290,270}})));
    Modelica.Blocks.Sources.RealExpression rooTem(y=senRooTem.T)
      annotation (Placement(transformation(extent={{-270,290},{-290,310}})));
    BaseClasses.PIController piController(yValMin=0.05, yFanMin=0.10)
      annotation (Placement(transformation(extent={{110,174},{38,246}})));
    BaseClasses.FilteredPowerMeter filteredPowerMeter
      annotation (Placement(transformation(extent={{-172,214},{-206,248}})));
  equation
    connect(fanRet.port_b, mixJun.port_3) annotation(
      Line(points = {{-162, -60}, {-162, 4}}, color = {0, 127, 255}));
    connect(resRet.port_b, fanRet.port_a) annotation(
      Line(points = {{-98, -60}, {-142, -60}}, color = {0, 127, 255}));
    connect(damOut.port_b, mixJun.port_1) annotation(
      Line(points = {{-176, 14}, {-172, 14}}, color = {0, 127, 255}));
    connect(senOutFlo.port_b, damOut.port_a) annotation(
      Line(points = {{-204, -8}, {-204, 14}, {-196, 14}}, color = {0, 127, 255}));
    connect(ambAir.ports[1], senOutFlo.port_a) annotation(
      Line(points={{-342,24.6667},{-342,-28},{-204,-28}},   color = {0, 127, 255}));
    connect(mixJun.port_2, senMixTem.port_a) annotation(
      Line(points = {{-152, 14}, {-142, 14}}, color = {0, 127, 255}));
    connect(winOpe.port_b1, ambAir.ports[2]) annotation(
      Line(points = {{-12, -90}, {-196, -90}, {-196, 26}, {-342, 26}}, color = {0, 127, 255}));
    connect(winOpe.port_a2, ambAir.ports[3]) annotation(
      Line(points={{-12,-102},{-212,-102},{-212,27.3333},{-342,27.3333}},color = {0, 127, 255}));
    connect(senMixTem.port_b, senSupFlo.port_a) annotation(
      Line(points = {{-122, 14}, {-112, 14}}, color = {0, 127, 255}));
    connect(senSupFlo.port_b, coiCoo.port_a2) annotation(
      Line(points = {{-92, 14}, {-68, 14}}, color = {0, 127, 255}));
    connect(coiCoo.port_b1, pumChi.port_a) annotation(
      Line(points = {{-68, 26}, {-84, 26}, {-84, 58}}, color = {0, 170, 0}));
    connect(senMasFloValv.port_b, coiCoo.port_a1) annotation(
      Line(points = {{-32, 60}, {-32, 26}, {-48, 26}}, color = {0, 170, 0}));
    connect(valChi.port_b, senMasFloValv.port_a) annotation(
      Line(points = {{-32, 102}, {-32, 80}}, color = {0, 170, 0}));
    connect(senSupTem.port_b, resSup.port_a) annotation(
      Line(points={{58,14},{60,14},{60,-2}},        color = {0, 127, 255}));
    connect(resSup.port_b, zon.ports[1]) annotation(
      Line(points={{60,-22},{60,-61.6},{47,-61.6}},    color = {0, 127, 255}));
    connect(senRetFlo.port_a, zon.ports[2]) annotation(
      Line(points={{14,-60},{30,-60},{30,-60.8},{47,-60.8}},
                                            color = {0, 127, 255}));
    connect(winOpe.port_a1, zon.ports[3]) annotation(
      Line(points={{8,-90},{36,-90},{36,-60},{47,-60}},          color = {0, 127, 255}));
    connect(winOpe.port_b2, zon.ports[4]) annotation(
      Line(points={{8,-102},{42,-102},{42,-59.2},{47,-59.2}},      color = {0, 127, 255}));
    connect(zon.heaPorAir, senRooTem.port) annotation(
      Line(points={{61,-50},{88,-50}},      color = {191, 0, 0}));
    connect(zon.surf_surBou[1], walWest.port_a) annotation(
      Line(points={{58.2,-64.4},{58.2,-90},{104,-90}},  color = {191, 0, 0}));
    connect(walWest.port_b, westTemBnd.port) annotation(
      Line(points = {{124, -90}, {160, -90}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[2], walEast.port_a) annotation(
      Line(points={{58.2,-64.2},{58.2,-126},{104,-126}},  color = {191, 0, 0}));
    connect(walEast.port_b, eastTemBnd.port) annotation(
      Line(points = {{124, -126}, {160, -126}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[3], floSlab.port_a) annotation(
      Line(points={{58.2,-64},{58.2,-160},{106,-160}},    color = {191, 0, 0}));
    connect(floSlab.port_b, floorTemBnd.port) annotation(
      Line(points = {{126, -160}, {160, -160}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[4], ceiSlab.port_a) annotation(
      Line(points={{58.2,-63.8},{58.2,-194},{106,-194}},  color = {191, 0, 0}));
    connect(ceiSlab.port_b, ceilTemBnd.port) annotation(
      Line(points = {{126, -194}, {160, -194}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[5], walNorth.port_a) annotation(
      Line(points={{58.2,-63.6},{58.2,-232},{38,-232}},  color = {191, 0, 0}));
    connect(walNorth.port_b, norTemBnd.port) annotation(
      Line(points = {{18, -232}, {-6, -232}}, color = {191, 0, 0}));
    connect(co2GenOcc.y, zon.C_flow[1]) annotation(
      Line(points={{-305,-168},{24,-168},{24,-47.2},{40.4,-47.2}},    color = {0, 0, 127}));
    connect(coiCoo.port_b2, fanSup.port_a) annotation(
      Line(points={{-48,14},{-16,14}},      color = {0, 127, 255}));
    connect(resRet.port_a, senRetCO2.port_b) annotation(
      Line(points = {{-78, -60}, {-52, -60}}, color = {0, 127, 255}));
    connect(senRetCO2.port_a, senRetFlo.port_b) annotation(
      Line(points = {{-32, -60}, {-6, -60}}, color = {0, 127, 255}));
    connect(misGainFra.y, intGains.misFra) annotation(
      Line(points={{-247,-196},{-230,-196},{-230,-195.16},{-218.8,-195.16}},  color = {0, 0, 127}));
    connect(occFra, intGains.occFra) annotation (Line(points={{-378,-180},{
            -218.8,-180},{-218.8,-184.8}}, color={0,0,127}));
    connect(heaFra, intGains.heaFra) annotation (Line(points={{-378,-216},{
            -218.8,-216},{-218.8,-205.8}}, color={0,0,127}));
    connect(intGains.yCon, gainMux.u2[1]) annotation(
      Line(points={{-186.6,-195.16},{-152,-195.16},{-152,-196},{-122,-196}},  color = {0, 0, 127}));
    connect(intGains.yLat, gainMux.u3[1]) annotation(
      Line(points={{-186.6,-205.8},{-122,-205.8},{-122,-203}},  color = {0, 0, 127}));
    connect(gainMux.y, zon.qGai_flow) annotation(
      Line(points={{-99,-196},{40.4,-196},{40.4,-42}},    color = {0, 0, 127}, thickness = 0.5));
    connect(valChi.y_actual, yValChi) annotation(
      Line(points={{-25,107},{-25,96},{-370,96}},                        color = {0, 0, 127}));
    connect(damOut.y_actual, yDamOut) annotation(
      Line(points={{-181,21},{-181,78},{-182,78},{-182,136},{-370,136}},            color = {0, 0, 127}));
    connect(fanSup.y_actual, yFanSup) annotation(
      Line(points={{5,21},{12,21},{12,46},{-290,46},{-290,114},{-370,114}},     color = {0, 0, 127}));
    connect(fanRet.y_actual, yFanRet) annotation(
      Line(points={{-163,-53},{-306,-53},{-306,78},{-370,78}},          color = {0, 0, 127}));
    connect(senRooTem.T, TRoo) annotation(
      Line(points={{109,-50},{108,-50},{108,-26},{-318,-26},{-318,62},{-370,62}},              color = {0, 0, 127}));
    connect(weaDat.weaBus, weaBus) annotation(
      Line(points={{-302,-85},{-288,-85},{-288,-84},{-272,-84}},
                                                color = {255, 204, 51}, thickness = 0.5));
    connect(roomLeak.weaBus, weaBus) annotation(
      Line(points={{-110,-147},{-272,-147},{-272,-84}},        color = {255, 204, 51}, thickness = 0.5));
    connect(ambAir.weaBus, weaBus) annotation(
      Line(points={{-362,26.2},{-362,-58},{-272,-58},{-272,-84}},        color = {255, 204, 51}, thickness = 0.5));
    connect(zon.weaBus, weaBus) annotation(
      Line(points={{79.9,-32.1},{79.9,-110},{-272,-110},{-272,-84}},    color = {255, 204, 51}, thickness = 0.5));
    connect(gaiOutTem.u, weaBus.TDryBul) annotation(
      Line(points={{-212,-226},{-271.95,-226},{-271.95,-83.95}},
                                                               color = {255, 204, 51}));
    connect(zonCO2.y, CO2Roo) annotation(
      Line(points={{-345,46},{-370,46}},                              color = {0, 0, 127}));
    connect(intGains.yRad, gainMux.u1[1]) annotation(
      Line(points={{-186.6,-185.36},{-122,-185.36},{-122,-189}},color = {0, 0, 127}));
    connect(gaiOutTem.y, corTemMix.u1) annotation(
      Line(points={{-189,-226},{-122,-226}},      color = {0, 0, 127}));
    connect(senRooTem.T, zonTemLag.u) annotation(
      Line(points={{109,-50},{192,-50},{192,-266},{42,-266}},          color = {0, 0, 127}));
    connect(zonTemLag.y, gaiZonTem.u) annotation(
      Line(points={{19,-266},{-6,-266}},      color = {0, 0, 127}));
    connect(gaiZonTem.y, corTemMix.u2) annotation(
      Line(points={{-29,-266},{-122,-266},{-122,-238}},        color = {0, 0, 127}));
    connect(corTemMix.y, norTemBnd.T) annotation(
      Line(points={{-99,-232},{-28,-232}},      color = {0, 0, 127}));
    connect(roomLeak.port_b, zon.ports[5]) annotation(
      Line(points={{-80,-147},{47,-147},{47,-58.4}},      color = {0, 127, 255}));
  connect(pumChi.port_b, senWatRetTem.port_a) annotation(
      Line(points = {{-84, 78}, {-84, 112}}, color = {0, 170, 0}));
  connect(senWatRetTem.port_b, chiWatRet.ports[1]) annotation(
      Line(points = {{-84, 132}, {-84, 170}}, color = {0, 170, 0}));
  connect(chiWatSup.ports[1], senWatSupTem.port_a) annotation(
      Line(points = {{-32, 170}, {-32, 154}}, color = {0, 170, 0}));
  connect(senWatSupTem.port_b, valChi.port_a) annotation(
      Line(points = {{-32, 134}, {-32, 122}}, color = {0, 170, 0}));
    connect(uWinOpe, winCmdFil.u) annotation (Line(points={{300,110},{248,110},
            {248,-97},{235.8,-97}},
                               color={0,0,127}));
    connect(winCmdFil.y, winOpe.y) annotation (Line(points={{215.1,-97},{154,-97},
            {154,-96},{9,-96}}, color={0,0,127}));
    connect(fanSup.port_b, senSupTem.port_a)
      annotation (Line(points={{4,14},{38,14}}, color={0,127,255}));
    connect(uWinOpe, winOpeBool.u) annotation (Line(points={{300,110},{239.9,110},
            {239.9,111},{179.8,111}},           color={0,0,127}));
    connect(uSysOn, sysOnBool.u) annotation (Line(points={{300,150},{204,150},{204,
            149},{181.8,149}},     color={0,0,127}));
    connect(rooPre.y, phi.p) annotation (Line(points={{-291,260},{-300,260.4},{-312.7,
            260.4}}, color={0,0,127}));
    connect(rooXw.y, phi.X_w) annotation (Line(points={{-291,280},{-300,280},{-300,
            270},{-312.7,270}}, color={0,0,127}));
    connect(rooTem.y, phi.T) annotation (Line(points={{-291,300},{-312.7,300},{-312.7,
            279.6}}, color={0,0,127}));
    connect(phi.phi, RhRoo)
      annotation (Line(points={{-341.3,270},{-370,270}}, color={0,0,127}));
    connect(PASHP, PASHP)
      annotation (Line(points={{-370,242},{-370,242}}, color={0,0,127}));
    connect(PFanRet, PFanRet)
      annotation (Line(points={{-370,192},{-370,192}}, color={0,0,127}));
    connect(sysOnBool.y, piController.sysOn) annotation (Line(points={{161.1,149},
            {102.8,149},{102.8,166.8}}, color={255,0,255}));
    connect(winOpeBool.y, piController.winOpe) annotation (Line(points={{159.1,111},
            {85.52,111},{85.52,166.8}}, color={255,0,255}));
    connect(TRooSet, piController.TRooSet) annotation (Line(points={{300,224},{236,
            224},{236,210},{117.2,210}}, color={0,0,127}));
    connect(CO2Set, piController.CO2Set) annotation (Line(points={{300,192},{224,192},
            {224,182},{117.2,182},{117.2,181.2}}, color={0,0,127}));
    connect(senSupTem.T, piController.TSup) annotation (Line(points={{48,25},{92,25},
            {92,26},{152,26},{152,238.8},{117.2,238.8}}, color={0,0,127}));
    connect(senRooTem.T, piController.TRoo) annotation (Line(points={{109,-50},{108,
            -50},{108,-26},{142,-26},{142,224.4},{117.2,224.4}}, color={0,0,127}));
    connect(senRetCO2.ppm, piController.CO2Meas) annotation (Line(points={{-42,-49},
            {-42,-14},{132,-14},{132,196},{117.2,196},{117.2,195.6}}, color={0,0,127}));
    connect(piController.yPumChi, pumChi.y) annotation (Line(points={{34.4,239.52},
            {-96,239.52},{-96,68}}, color={0,0,127}));
    connect(piController.yValChi, valChi.y) annotation (Line(points={{34.4,226.56},
            {-20,226.56},{-20,112}}, color={0,0,127}));
    connect(piController.yFanSup, fanSup.y) annotation (Line(points={{34.4,206.4},
            {-6,206.4},{-6,26}}, color={0,0,127}));
    connect(piController.yFanRet, fanRet.y) annotation (Line(points={{34.4,194.16},
            {-58,194.16},{-58,194},{-152,194},{-152,-48}}, color={0,0,127}));
    connect(piController.yDamOut, damOut.y) annotation (Line(points={{34.4,180.48},
            {32,180.48},{32,180},{-186,180},{-186,26}}, color={0,0,127}));
    connect(senWatSupTem.T, filteredPowerMeter.TWatSup) annotation (Line(points
          ={{-43,144},{-112,144},{-112,248},{-168.6,248}}, color={0,0,127}));
    connect(senWatRetTem.T, filteredPowerMeter.TWatRet) annotation (Line(points
          ={{-95,122},{-122,122},{-122,241.2},{-168.6,241.2}}, color={0,0,127}));
    connect(senMasFloValv.m_flow, filteredPowerMeter.mChiWat) annotation (Line(
          points={{-21,70},{-20,70},{-20,86},{-132,86},{-132,234.4},{-168.6,
            234.4}}, color={0,0,127}));
    connect(pumChi.P, filteredPowerMeter.PPump) annotation (Line(points={{-93,
            79},{-93,112},{-142,112},{-142,227.6},{-168.6,227.6}}, color={0,0,
            127}));
    connect(fanSup.P, filteredPowerMeter.PSupFanAll) annotation (Line(points={{
            5,23},{5,56},{-158,56},{-158,220.8},{-168.6,220.8}}, color={0,0,127}));
    connect(fanRet.P, filteredPowerMeter.PRetFanAll) annotation (Line(points={{
            -163,-51},{-168.6,-51},{-168.6,214}}, color={0,0,127}));
    connect(sysOnBool.y, filteredPowerMeter.sysOn) annotation (Line(points={{
            161.1,149},{-8,149},{-8,150},{-176,150},{-176,210.6},{-175.4,210.6}},
          color={255,0,255}));
    connect(filteredPowerMeter.PASHP, PASHP) annotation (Line(points={{-207.7,
            246.3},{-264,246.3},{-264,242},{-370,242}}, color={0,0,127}));
    connect(filteredPowerMeter.PPumChi, PPumChi) annotation (Line(points={{
            -207.7,236.1},{-348,236.1},{-348,224},{-370,224}}, color={0,0,127}));
    connect(filteredPowerMeter.PSupFan, PFanSup) annotation (Line(points={{
            -207.7,225.9},{-340,225.9},{-340,206},{-370,206}}, color={0,0,127}));
    connect(filteredPowerMeter.PRetFan, PFanRet) annotation (Line(points={{
            -207.7,215.7},{-336,215.7},{-336,192},{-370,192}}, color={0,0,127}));
    annotation(
      Icon(coordinateSystem(extent = {{-100, 100}, {100, -100}}), graphics = {Rectangle(origin = {2, -1}, lineColor = {0, 0, 255}, fillColor = {173, 216, 230}, fillPattern = FillPattern.Solid, extent = {{-102, 101}, {102, -101}}), Text(origin = {0, 4}, extent = {{-98, 94}, {98, -94}}, textString = "HCD", fontSize = 50)}),
      Diagram(coordinateSystem(extent = {{-380, 320}, {300, -280}})),
      experiment(
        StopTime=1440000,
        Interval=1,
        __Dymola_Algorithm="Ida"));
  end HCDLabPMVPIEval;

  model HCDLabPMVPITrain
    // FMU
    // inputs
    Modelica.Blocks.Interfaces.RealInput TRooSet "Zone temperature setpoint [K]" annotation(
      Placement(transformation(origin={300,224},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, -20}, extent = {{-20, -20}, {20, 20}})));
    Modelica.Blocks.Interfaces.RealInput CO2Set "CO2 setpoint [ppm]" annotation(
      Placement(transformation(origin={300,192},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 20}, extent = {{-20, -20}, {20, 20}})));
    Modelica.Blocks.Interfaces.RealInput uWinOpe
      "Window command: 0=closed, >0.1=open"                                            annotation(
      Placement(transformation(origin={300,110},    extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {-120, 100}, extent = {{-20, -20}, {20, 20}})));
    Modelica.Blocks.Interfaces.RealInput heaFra
      "Internal heat gain fraction (0..1)" annotation (Placement(transformation(
            origin={-378,-216}, extent={{-20,-20},{20,20}}), iconTransformation(
            origin={-120,-60}, extent={{-20,-20},{20,20}})));
    Modelica.Blocks.Interfaces.RealInput occFra "Occupancy fraction (0..1)"
      annotation (Placement(transformation(origin={-378,-180}, extent={{-20,-20},
              {20,20}}), iconTransformation(origin={-120,-100}, extent={{-20,-20},
              {20,20}})));
    // outputs
    Modelica.Blocks.Interfaces.RealOutput yValChi "Cooling valve actual position (0..1)" annotation(
      Placement(transformation(origin={-370,96},     extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 70}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PPumChi "Pump electrical power [W]" annotation(
      Placement(transformation(origin={-370,224},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -90}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput yDamOut "Outdoor-air damper actual position (0..1)" annotation(
      Placement(transformation(origin={-370,136},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -70}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PFanSup "Supply fan electrical power [W]" annotation(
      Placement(transformation(origin={-370,206},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -50}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput yFanSup "Supply fan actual speed (0..1)" annotation(
      Placement(transformation(origin={-370,114},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -30}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput yFanRet "Return fan actual speed (0..1)" annotation(
      Placement(transformation(origin={-370,78},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -10}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PFanRet "Return fan electrical power [W]" annotation(
      Placement(transformation(origin={-370,192},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 10}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput TRoo "Zone air temperature [K]" annotation(
      Placement(transformation(origin={-370,62},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 30}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput CO2Roo "Zone CO2 concentration [ppm]" annotation(
      Placement(transformation(origin={-370,46},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, 50}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput PASHP annotation(
      Placement(transformation(origin={-370,242},    extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {114, -90}, extent = {{-10, -10}, {10, 10}})));
    //
    replaceable package MediumA = Buildings.Media.Air(extraPropertiesNames = {"CO2"}) "Medium for air";
    replaceable package MediumW = Buildings.Media.Water "Medium for water";
    parameter Modelica.Units.SI.Length xIntMass = 0.01481324 "Effective thickness of internal mass layer (m) (calibrated)";
    parameter Modelica.Units.SI.Area AIntMass(min = 0) = 2*AFlo "Effective internal mass area (m2)";
    parameter Real nOccMax = 10 "Max number of occupants";
    parameter Real wCorOut(min = 0, max = 1) = 0.7 "Corridor temperature weight on outdoor";
    parameter Modelica.Units.SI.MassFlowRate mFlowNominal = 1;
    parameter Modelica.Units.SI.Height hRoo = 2.6 "Room height";
    parameter Modelica.Units.SI.Area AFlo = 81.76 "Floor area";
    parameter Modelica.Units.SI.Area ACeil = 81.76 "Ceiling area";
    parameter Modelica.Units.SI.Volume VRoo = 221.559 "Room volume";
    parameter Modelica.Units.SI.Length wExtSou = 7.3 "South exterior wall width";
    parameter Modelica.Units.SI.Length wIntNor = 7.3 "North interior wall width";
    parameter Modelica.Units.SI.Length wIntWes = 11.2 "West interior wall width";
    parameter Modelica.Units.SI.Length wIntEas = 11.2 "East interior wall width";
    parameter Real winWalRat(min = 0.01, max = 0.99) = 0.95 "Window to wall ratio for exterior walls";
    parameter Modelica.Units.SI.Length hWin = 2.6 "Height of windows (south)";
    // fixed neighbor temps (Kelvin)
    parameter Modelica.Units.SI.Temperature TWes = 300.15;
    parameter Modelica.Units.SI.Temperature TEas = 300.15;
    parameter Modelica.Units.SI.Temperature TFlo = 300.15;
    parameter Modelica.Units.SI.Temperature TCei = 300.15;
    ///////////////////////////////Materials\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matCon(x = 0.4, k = 1.311, c = 836, nStaRef = 5) "Concrete" annotation(
      Placement(transformation(origin={-170,304},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matAirGapFlo(c = 1006, d = 1.2, k = 0.026, nStaRef = 1, x = 0.112) "Air cavity (conduction-only approximation)" annotation(
      Placement(transformation(origin={-138,304},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matCemBoa(c = 837, d = 1922, k = 0.597, nStaRef = 1, x = 0.032) "Cement board (Cementitious fill)" annotation(
      Placement(transformation(origin={-106,304},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matCar(x = 0.006, k = 0.06, c = 1360, nStaRef = 1, d = 186) "Carpet" annotation(
      Placement(transformation(origin={-74,304},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matConWal(c = 836, k = 1.311, nStaRef = 2, x = 0.15) "Concrete for west, east, and south walls" annotation(
      Placement(transformation(origin={-106,280},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matConWalNor(c = 836, k = 1.311, nStaRef = 2, x = 0.26103384) "Concrete for north wall (window and door negleted), calibrate x" annotation(
      Placement(transformation(origin={-74,280},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Generic matAirGapCei(c = 1006, d = 1.2, k = 0.026, nStaRef = 1, x = 0.525) annotation(
      Placement(transformation(origin={-170,280},    extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.GypsumBoard matGypBoa(x = 0.01) annotation(
      Placement(transformation(origin={-138,280},    extent = {{-10, -10}, {10, 10}})));
    ///////////////////////////OpaqueConstructions\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conExtWalS(final nLay = 1, material = {matConWal}) "South Exterior construction" annotation(
      Placement(transformation(origin={-12,304},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntWalN(final nLay = 1, material = {matConWalNor}) "North Interior construction (facing corridor)" annotation(
      Placement(transformation(origin={18,304},      extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntWalW(final nLay = 1, material = {matConWal}) "West Interior wall construction" annotation(
      Placement(transformation(origin={48,304},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntWalE(final nLay = 1, material = {matConWal}) "East Interior wall construction" annotation(
      Placement(transformation(origin={48,280},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntFlo(final nLay = 4, material = {matCon, matAirGapFlo, matCemBoa, matCar}) "Floor construction" annotation(
      Placement(transformation(origin={-12,280},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntCeil(final nLay = 3, material = {matCon, matAirGapCei, matGypBoa}) "Ceiling construction" annotation(
      Placement(transformation(origin={18,280},      extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.Solids.Concrete matIntMass(c = 836, k = 1.311, nStaRef = 2, x = xIntMass) annotation(
      Placement(transformation(origin={78,306},     extent = {{-10, -10}, {10, 10}})));
    parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic conIntMass(material = {matIntMass}, final nLay = 1) annotation(
      Placement(transformation(origin={78,280},     extent = {{-10, -10}, {10, 10}})));
    //////////////////////////////glazing system\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Data.GlazingSystems.DoubleClearAir13Clear glaSysS(UFra = 2, shade = Buildings.HeatTransfer.Data.Shades.Gray(), haveInteriorShade = false, haveExteriorShade = false) "Data record for the south glazing system" annotation(
      Placement(transformation(origin={-42,304},     extent = {{-10, -10}, {10, 10}})));
    ////////////////////////////////zone\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    parameter Buildings.HeatTransfer.Types.InteriorConvection intConMod = Buildings.HeatTransfer.Types.InteriorConvection.Temperature "Convective heat transfer model for room-facing surfaces of opaque constructions";
    parameter Boolean sampleModel = false "Set to true to time-sample the model, which can give shorter simulation time if there is already time sampling in the system model" annotation(
      Evaluate = true,
      Dialog(tab = "Experimental (may be changed in future releases)"));
    Buildings.HeatTransfer.Sources.FixedTemperature westTemBnd(T = TWes) annotation(
      Placement(transformation(origin = {170, -90}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.FixedTemperature eastTemBnd(T = TEas) annotation(
      Placement(transformation(origin = {170, -126}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.FixedTemperature floorTemBnd(T = TFlo) annotation(
      Placement(transformation(origin = {170, -160}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.FixedTemperature ceilTemBnd(T = TCei) annotation(
      Placement(transformation(origin = {170, -194}, extent = {{10, -10}, {-10, 10}})));
    Buildings.HeatTransfer.Sources.PrescribedTemperature norTemBnd annotation(
      Placement(transformation(origin = {-16, -232}, extent = {{-10, -10}, {10, 10}})));
    /// zone \\\
    Buildings.ThermalZones.Detailed.MixedAir zon(redeclare package Medium = MediumA, AFlo = AFlo, hRoo = hRoo, use_C_flow = true, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC), nConExt = 0,  // >>>  Exterior with windows <<<
    nConExtWin = 1, datConExtWin(layers = {conExtWalS}, A = {wExtSou*hRoo}, glaSys = {glaSysS}, wWin = {winWalRat/hWin*wExtSou*hRoo}, each hWin = hWin, fFra = {0.2}, til = {Buildings.Types.Tilt.Wall}, azi = {Buildings.Types.Azimuth.S}),  // >>> Parallel constructions: internal masses <<<
    final nConPar = 1, datConPar(layers = {conIntMass}, A = {AIntMass}, til = {Buildings.Types.Tilt.Wall}, azi = {Buildings.Types.Azimuth.S}),  // >>> explicitly constructed shared walls <<<
    final nConBou = 0,  // >>> passive boundary surfaces with external heat ports <<<
    final nSurBou = 5, surBou(A = {wIntWes*hRoo, wIntEas*hRoo, AFlo, ACeil, wIntNor*hRoo}, til = {Buildings.Types.Tilt.Wall, Buildings.Types.Tilt.Wall, Buildings.Types.Tilt.Floor, Buildings.Types.Tilt.Ceiling, Buildings.Types.Tilt.Wall}, each absIR = 0.9, each absSol = 0.9), nPorts = 5, intConMod = intConMod, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, final sampleModel = sampleModel) annotation(
      Placement(transformation(origin = {62, -50}, extent = {{-20, -20}, {20, 20}})));
    /// interior walls \\\
    Buildings.HeatTransfer.Conduction.MultiLayer walWest(A = wIntWes*hRoo, layers(nLay = 1, material = {matConWal}), T_a_start = TWes, T_b_start = TWes) annotation(
      Placement(transformation(origin = {114, -90}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer walEast(A = wIntEas*hRoo, T_a_start = TEas, T_b_start = TEas, layers(nLay = 1, material = {matConWal})) annotation(
      Placement(transformation(origin = {114, -126}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer floSlab(A = AFlo, T_a_start = TFlo, T_b_start = TFlo, layers(nLay = 4, material = {matCon, matAirGapFlo, matCemBoa, matCar})) annotation(
      Placement(transformation(origin = {116, -160}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer ceiSlab(A = ACeil, T_a_start = TCei, T_b_start = TCei, layers(material = {matCon, matAirGapCei, matGypBoa}, nLay = 3)) annotation(
      Placement(transformation(origin = {116, -194}, extent = {{-10, -10}, {10, 10}})));
    Buildings.HeatTransfer.Conduction.MultiLayer walNorth(A = wIntNor*hRoo, T_a_start = 297.15, T_b_start = 297.15, layers(material = {matConWalNor}, nLay = 1), steadyStateInitial = false) annotation(
      Placement(transformation(origin = {28, -232}, extent = {{10, -10}, {-10, 10}})));
    // corridor boundary temperature model
    Modelica.Blocks.Continuous.FirstOrder zonTemLag(T = 600) annotation(
      Placement(transformation(origin = {30, -266}, extent = {{10, -10}, {-10, 10}})));
    Modelica.Blocks.Math.Gain gaiZonTem(k = 1 - wCorOut) "Zone temperature weight" annotation(
      Placement(transformation(origin = {-18, -266}, extent = {{10, -10}, {-10, 10}})));
    Modelica.Blocks.Math.Gain gaiOutTem(k = wCorOut) annotation(
      Placement(transformation(origin = {-200, -226}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Add corTemMix annotation(
      Placement(transformation(origin = {-110, -232}, extent = {{-10, -10}, {10, 10}})));
    // heat and co2 gain
    Modelica.Blocks.Sources.RealExpression co2GenOcc(y=occFra*nOccMax*9.6e-6)
      "0.0052 L/s-person with co2 density about 1.84 kg/m3"
                   annotation (Placement(transformation(origin={-316,-168},
            extent={{-10,-10},{10,10}})));
    MMV_clean.BaseClasses.InternalGains3 intGains(
      qHea_Wm2=30.24,
      qMis_Wm2=3.2116997,
      qOcc_nominal_Wm2=14.5548) annotation (Placement(transformation(origin={-202,
              -196}, extent={{-14,-14},{14,14}})));
    Modelica.Blocks.Sources.Constant misGainFra(k = 1) annotation(
      Placement(transformation(origin = {-258, -196}, extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Routing.Multiplex3 gainMux annotation(
      Placement(transformation(origin = {-110, -196}, extent = {{-10, -10}, {10, 10}})));
    ////////////////////////////////HVAC\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    Buildings.Fluid.Movers.SpeedControlled_y pumChi(redeclare package Medium = MediumW, addPowerToMedium = false, energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyState, inputType = Buildings.Fluid.Types.InputType.Continuous, redeclare MMV_clean.BaseClasses.Pump_per
                                                                                                                                                                                                        per, use_inputFilter = true, riseTime = 600,
      allowFlowReversal=false)                                                                                                                                                                                                         annotation(
      Placement(transformation(origin = {-84, 68}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Buildings.Fluid.Actuators.Valves.TwoWayEqualPercentage valChi(redeclare package Medium = MediumW, m_flow_nominal = 0.5, dpValve_nominal = 2000, dpFixed_nominal = 1000, use_inputFilter = true,
      riseTime=180,
      allowFlowReversal=false)                                                                                                                                                                                                         annotation(
      Placement(transformation(origin = {-32, 112}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.HeatExchangers.WetCoilEffectivenessNTU coiCoo(redeclare package Medium2 = MediumA, redeclare package Medium1 = MediumW, m1_flow_nominal = 3, m2_flow_nominal = 1, dp1_nominal = 1000, dp2_nominal = 0,
      energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
      UA_nominal=1300,                                                                                                                                                                                                        configuration = Buildings.Fluid.Types.HeatExchangerConfiguration.CounterFlow,
      allowFlowReversal1=false,
      allowFlowReversal2=false)                                                                                                                                                                                                        annotation(
      Placement(transformation(origin = {-58, 20}, extent = {{10, -10}, {-10, 10}})));
    Buildings.Fluid.Movers.SpeedControlled_y fanSup(redeclare package Medium = MediumA,
      energyDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial,                                                                                     redeclare MMV_clean.BaseClasses.FAN_per
                                                                                                                                                                                             per, inputType = Buildings.Fluid.Types.InputType.Continuous, addPowerToMedium = false, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC),
      allowFlowReversal=true,                                                                                                                                                                                                        m_flow(start = 1), dp(start = 10), C_nominal = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC), use_inputFilter = true, riseTime = 60) annotation(
      Placement(transformation(origin={-6,14},    extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Movers.SpeedControlled_y fanRet(redeclare package Medium = MediumA, addPowerToMedium = false,
      energyDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial,                                                                                                               inputType = Buildings.Fluid.Types.InputType.Continuous, redeclare MMV_clean.BaseClasses.FAN_per
                                                                                                                                                                                                        per, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC),
      allowFlowReversal=true,
      riseTime=60,                                                                                                                                                                                                        m_flow(start = 1), dp(start = 10), C_nominal = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC)) annotation(
      Placement(transformation(origin = {-152, -60}, extent = {{10, -10}, {-10, 10}})));
    Buildings.Fluid.Actuators.Dampers.Exponential damOut(redeclare package Medium = MediumA, dpDamper_nominal = 1473.57487105, m_flow_nominal = mFlowNominal, dpFixed_nominal = 138.64528868, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-186, 14}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
    Buildings.Fluid.FixedResistances.Junction mixJun(m_flow_nominal = {1, -2, 1}, dp_nominal = {2000, -500, 500}, redeclare package Medium = MediumA, C_start = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC), C_nominal = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC)) annotation(
      Placement(transformation(origin = {-162, 14}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.FixedResistances.PressureDrop resSup(redeclare package Medium = MediumA, m_flow_nominal = 1, dp_nominal = 262.62076974, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {60, -12}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.FixedResistances.PressureDrop resRet(redeclare package Medium = MediumA, dp_nominal = 223.38405591, m_flow_nominal = 1, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-88, -60}, extent = {{10, -10}, {-10, 10}})));
    BaseClasses.RoomLeakage roomLeak(redeclare package Medium = MediumA, VRoo = VRoo, s = 1, azi = 0, amb(C = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC))) annotation(
      Placement(transformation(origin = {-95, -147}, extent = {{-15, -15}, {15, 15}})));
    // operable window
    Buildings.Airflow.Multizone.DoorDiscretizedOperable winOpe(wOpe = 7.3/2, hOpe = 2.6, hA = hRoo/2, hB = hRoo/2, redeclare package Medium = MediumA, LClo = 0.005) annotation(
      Placement(transformation(origin = {-2, -96}, extent = {{10, -10}, {-10, 10}})));
    // sensors
    Buildings.Fluid.Sensors.TemperatureTwoPort senMixTem(redeclare package Medium = MediumA, m_flow_nominal = mFlowNominal, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-132, 14}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sensors.TemperatureTwoPort senSupTem(redeclare package Medium = MediumA, m_flow_nominal = mFlowNominal, allowFlowReversal = true) annotation(
      Placement(transformation(origin={48,14},    extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sensors.MassFlowRate senSupFlo(redeclare package Medium = MediumA, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-102, 14}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sensors.MassFlowRate senRetFlo(redeclare package Medium = MediumA, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {4, -60}, extent = {{10, -10}, {-10, 10}})));
    Buildings.Fluid.Sensors.MassFlowRate senOutFlo(redeclare package Medium = MediumA) annotation(
      Placement(transformation(origin = {-204, -18}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Buildings.Fluid.Sensors.MassFlowRate senMasFloValv(redeclare package Medium = MediumW, allowFlowReversal = true) annotation(
      Placement(transformation(origin = {-32, 70}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.Sensors.PPMTwoPort senRetCO2(redeclare package Medium = MediumA, m_flow_nominal = 1, allowFlowReversal = true, C_start = 400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM) annotation(
      Placement(transformation(origin = {-42, -60}, extent = {{10, -10}, {-10, 10}})));
    Modelica.Blocks.Sources.RealExpression zonCO2(y = zon.air.vol.C[1]*1e6*Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM/Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM) annotation(
      Placement(transformation(origin={-334,46},   extent = {{10, -10}, {-10, 10}}, rotation = -0)));
    Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor senRooTem annotation(
      Placement(transformation(origin = {98, -50}, extent = {{-10, -10}, {10, 10}})));

    // boundaries
    Buildings.BoundaryConditions.WeatherData.Bus weaBus annotation(
      Placement(transformation(origin={-272,-84},    extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-88, 88}, extent = {{-10, -10}, {10, 10}})));
    Buildings.Fluid.Sources.Outside ambAir(nPorts = 3, redeclare package Medium = MediumA, use_C_in = false, C = fill(400e-6*Modelica.Media.IdealGases.Common.SingleGasesData.CO2.MM/Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, MediumA.nC)) annotation(
      Placement(transformation(origin = {-352, 26}, extent = {{-10, -10}, {10, 10}})));
    Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(filNam=
          Modelica.Utilities.Files.loadResource(
          "modelica://Buildings/Resources/weatherdata/SGP_SG_Singapore-Changi.Intl.AP.486980_TMYx.2004-2018.mos"))                                                                                            annotation(
      Placement(transformation(origin={-317,-83},    extent={{-15,-15},{15,15}})));
    Buildings.Fluid.Sources.Boundary_pT chiWatSup(T = 282.15, redeclare package Medium = MediumW, nPorts = 1) annotation(
      Placement(transformation(origin = {-32, 180}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Buildings.Fluid.Sources.Boundary_pT chiWatRet(redeclare package Medium = MediumW, nPorts = 1) annotation(
      Placement(transformation(origin = {-84, 180}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    ////////////////////////////////SP tracking\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  Buildings.Fluid.Sensors.TemperatureTwoPort senWatRetTem(redeclare package Medium = MediumW, m_flow_nominal = 3) annotation(
      Placement(transformation(origin = {-84, 122}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Buildings.Fluid.Sensors.TemperatureTwoPort senWatSupTem(redeclare package Medium = MediumW, m_flow_nominal = 3) annotation(
      Placement(transformation(origin = {-32, 144}, extent = {{-10, 10}, {10, -10}}, rotation = -90)));

    Modelica.Blocks.Continuous.FirstOrder winCmdFil(k=1, T=120)
      annotation (Placement(transformation(extent={{234,-106},{216,-88}})));

    Modelica.Blocks.Math.RealToBoolean winOpeBool(threshold=0.1)
      annotation (Placement(transformation(extent={{178,102},{160,120}})));
    Modelica.Blocks.Math.RealToBoolean sysOnBool(threshold=0.1)
      annotation (Placement(transformation(extent={{180,140},{162,158}})));
    Modelica.Blocks.Interfaces.RealInput uSysOn
      "System command: 0=off, >0.1=on" annotation (Placement(transformation(
            origin={300,150}, extent={{20,-20},{-20,20}}), iconTransformation(
            origin={-120,100}, extent={{-20,-20},{20,20}})));
    Buildings.Utilities.Psychrometrics.Phi_pTX phi
      annotation (Placement(transformation(extent={{-314,258},{-340,282}})));
    Modelica.Blocks.Interfaces.RealOutput RhRoo "Zone relative humidity [0..1]"
      annotation (Placement(transformation(extent={{-360,260},{-380,280}})));
    Modelica.Blocks.Sources.RealExpression rooXw(y=zon.air.vol.X_w)
      annotation (Placement(transformation(extent={{-270,270},{-290,290}})));
    Modelica.Blocks.Sources.RealExpression rooPre(y=zon.ports[1].p)
      annotation (Placement(transformation(extent={{-270,250},{-290,270}})));
    Modelica.Blocks.Sources.RealExpression rooTem(y=senRooTem.T)
      annotation (Placement(transformation(extent={{-270,290},{-290,310}})));
    BaseClasses.PIController piController(yValMin=0.05, yFanMin=0.10)
      annotation (Placement(transformation(extent={{110,174},{38,246}})));
    BaseClasses.FilteredPowerMeter filteredPowerMeter
      annotation (Placement(transformation(extent={{-172,214},{-206,248}})));
  equation
    connect(fanRet.port_b, mixJun.port_3) annotation(
      Line(points = {{-162, -60}, {-162, 4}}, color = {0, 127, 255}));
    connect(resRet.port_b, fanRet.port_a) annotation(
      Line(points = {{-98, -60}, {-142, -60}}, color = {0, 127, 255}));
    connect(damOut.port_b, mixJun.port_1) annotation(
      Line(points = {{-176, 14}, {-172, 14}}, color = {0, 127, 255}));
    connect(senOutFlo.port_b, damOut.port_a) annotation(
      Line(points = {{-204, -8}, {-204, 14}, {-196, 14}}, color = {0, 127, 255}));
    connect(ambAir.ports[1], senOutFlo.port_a) annotation(
      Line(points={{-342,24.6667},{-342,-28},{-204,-28}},   color = {0, 127, 255}));
    connect(mixJun.port_2, senMixTem.port_a) annotation(
      Line(points = {{-152, 14}, {-142, 14}}, color = {0, 127, 255}));
    connect(winOpe.port_b1, ambAir.ports[2]) annotation(
      Line(points = {{-12, -90}, {-196, -90}, {-196, 26}, {-342, 26}}, color = {0, 127, 255}));
    connect(winOpe.port_a2, ambAir.ports[3]) annotation(
      Line(points={{-12,-102},{-212,-102},{-212,27.3333},{-342,27.3333}},color = {0, 127, 255}));
    connect(senMixTem.port_b, senSupFlo.port_a) annotation(
      Line(points = {{-122, 14}, {-112, 14}}, color = {0, 127, 255}));
    connect(senSupFlo.port_b, coiCoo.port_a2) annotation(
      Line(points = {{-92, 14}, {-68, 14}}, color = {0, 127, 255}));
    connect(coiCoo.port_b1, pumChi.port_a) annotation(
      Line(points = {{-68, 26}, {-84, 26}, {-84, 58}}, color = {0, 170, 0}));
    connect(senMasFloValv.port_b, coiCoo.port_a1) annotation(
      Line(points = {{-32, 60}, {-32, 26}, {-48, 26}}, color = {0, 170, 0}));
    connect(valChi.port_b, senMasFloValv.port_a) annotation(
      Line(points = {{-32, 102}, {-32, 80}}, color = {0, 170, 0}));
    connect(senSupTem.port_b, resSup.port_a) annotation(
      Line(points={{58,14},{60,14},{60,-2}},        color = {0, 127, 255}));
    connect(resSup.port_b, zon.ports[1]) annotation(
      Line(points={{60,-22},{60,-61.6},{47,-61.6}},    color = {0, 127, 255}));
    connect(senRetFlo.port_a, zon.ports[2]) annotation(
      Line(points={{14,-60},{30,-60},{30,-60.8},{47,-60.8}},
                                            color = {0, 127, 255}));
    connect(winOpe.port_a1, zon.ports[3]) annotation(
      Line(points={{8,-90},{36,-90},{36,-60},{47,-60}},          color = {0, 127, 255}));
    connect(winOpe.port_b2, zon.ports[4]) annotation(
      Line(points={{8,-102},{42,-102},{42,-59.2},{47,-59.2}},      color = {0, 127, 255}));
    connect(zon.heaPorAir, senRooTem.port) annotation(
      Line(points={{61,-50},{88,-50}},      color = {191, 0, 0}));
    connect(zon.surf_surBou[1], walWest.port_a) annotation(
      Line(points={{58.2,-64.4},{58.2,-90},{104,-90}},  color = {191, 0, 0}));
    connect(walWest.port_b, westTemBnd.port) annotation(
      Line(points = {{124, -90}, {160, -90}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[2], walEast.port_a) annotation(
      Line(points={{58.2,-64.2},{58.2,-126},{104,-126}},  color = {191, 0, 0}));
    connect(walEast.port_b, eastTemBnd.port) annotation(
      Line(points = {{124, -126}, {160, -126}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[3], floSlab.port_a) annotation(
      Line(points={{58.2,-64},{58.2,-160},{106,-160}},    color = {191, 0, 0}));
    connect(floSlab.port_b, floorTemBnd.port) annotation(
      Line(points = {{126, -160}, {160, -160}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[4], ceiSlab.port_a) annotation(
      Line(points={{58.2,-63.8},{58.2,-194},{106,-194}},  color = {191, 0, 0}));
    connect(ceiSlab.port_b, ceilTemBnd.port) annotation(
      Line(points = {{126, -194}, {160, -194}}, color = {191, 0, 0}));
    connect(zon.surf_surBou[5], walNorth.port_a) annotation(
      Line(points={{58.2,-63.6},{58.2,-232},{38,-232}},  color = {191, 0, 0}));
    connect(walNorth.port_b, norTemBnd.port) annotation(
      Line(points = {{18, -232}, {-6, -232}}, color = {191, 0, 0}));
    connect(co2GenOcc.y, zon.C_flow[1]) annotation(
      Line(points={{-305,-168},{24,-168},{24,-47.2},{40.4,-47.2}},    color = {0, 0, 127}));
    connect(coiCoo.port_b2, fanSup.port_a) annotation(
      Line(points={{-48,14},{-16,14}},      color = {0, 127, 255}));
    connect(resRet.port_a, senRetCO2.port_b) annotation(
      Line(points = {{-78, -60}, {-52, -60}}, color = {0, 127, 255}));
    connect(senRetCO2.port_a, senRetFlo.port_b) annotation(
      Line(points = {{-32, -60}, {-6, -60}}, color = {0, 127, 255}));
    connect(misGainFra.y, intGains.misFra) annotation(
      Line(points={{-247,-196},{-230,-196},{-230,-195.16},{-218.8,-195.16}},  color = {0, 0, 127}));
    connect(occFra, intGains.occFra) annotation (Line(points={{-378,-180},{
            -218.8,-180},{-218.8,-184.8}}, color={0,0,127}));
    connect(heaFra, intGains.heaFra) annotation (Line(points={{-378,-216},{
            -218.8,-216},{-218.8,-205.8}}, color={0,0,127}));
    connect(intGains.yCon, gainMux.u2[1]) annotation(
      Line(points={{-186.6,-195.16},{-152,-195.16},{-152,-196},{-122,-196}},  color = {0, 0, 127}));
    connect(intGains.yLat, gainMux.u3[1]) annotation(
      Line(points={{-186.6,-205.8},{-122,-205.8},{-122,-203}},  color = {0, 0, 127}));
    connect(gainMux.y, zon.qGai_flow) annotation(
      Line(points={{-99,-196},{40.4,-196},{40.4,-42}},    color = {0, 0, 127}, thickness = 0.5));
    connect(valChi.y_actual, yValChi) annotation(
      Line(points={{-25,107},{-25,96},{-370,96}},                        color = {0, 0, 127}));
    connect(damOut.y_actual, yDamOut) annotation(
      Line(points={{-181,21},{-181,78},{-182,78},{-182,136},{-370,136}},            color = {0, 0, 127}));
    connect(fanSup.y_actual, yFanSup) annotation(
      Line(points={{5,21},{12,21},{12,46},{-290,46},{-290,114},{-370,114}},     color = {0, 0, 127}));
    connect(fanRet.y_actual, yFanRet) annotation(
      Line(points={{-163,-53},{-306,-53},{-306,78},{-370,78}},          color = {0, 0, 127}));
    connect(senRooTem.T, TRoo) annotation(
      Line(points={{109,-50},{108,-50},{108,-26},{-318,-26},{-318,62},{-370,62}},              color = {0, 0, 127}));
    connect(weaDat.weaBus, weaBus) annotation(
      Line(points={{-302,-83},{-288,-83},{-288,-84},{-272,-84}},
                                                color = {255, 204, 51}, thickness = 0.5));
    connect(roomLeak.weaBus, weaBus) annotation(
      Line(points={{-110,-147},{-272,-147},{-272,-84}},        color = {255, 204, 51}, thickness = 0.5));
    connect(ambAir.weaBus, weaBus) annotation(
      Line(points={{-362,26.2},{-362,-58},{-272,-58},{-272,-84}},        color = {255, 204, 51}, thickness = 0.5));
    connect(zon.weaBus, weaBus) annotation(
      Line(points={{79.9,-32.1},{79.9,-110},{-272,-110},{-272,-84}},    color = {255, 204, 51}, thickness = 0.5));
    connect(gaiOutTem.u, weaBus.TDryBul) annotation(
      Line(points={{-212,-226},{-271.95,-226},{-271.95,-83.95}},
                                                               color = {255, 204, 51}));
    connect(zonCO2.y, CO2Roo) annotation(
      Line(points={{-345,46},{-370,46}},                              color = {0, 0, 127}));
    connect(intGains.yRad, gainMux.u1[1]) annotation(
      Line(points={{-186.6,-185.36},{-122,-185.36},{-122,-189}},color = {0, 0, 127}));
    connect(gaiOutTem.y, corTemMix.u1) annotation(
      Line(points={{-189,-226},{-122,-226}},      color = {0, 0, 127}));
    connect(senRooTem.T, zonTemLag.u) annotation(
      Line(points={{109,-50},{192,-50},{192,-266},{42,-266}},          color = {0, 0, 127}));
    connect(zonTemLag.y, gaiZonTem.u) annotation(
      Line(points={{19,-266},{-6,-266}},      color = {0, 0, 127}));
    connect(gaiZonTem.y, corTemMix.u2) annotation(
      Line(points={{-29,-266},{-122,-266},{-122,-238}},        color = {0, 0, 127}));
    connect(corTemMix.y, norTemBnd.T) annotation(
      Line(points={{-99,-232},{-28,-232}},      color = {0, 0, 127}));
    connect(roomLeak.port_b, zon.ports[5]) annotation(
      Line(points={{-80,-147},{47,-147},{47,-58.4}},      color = {0, 127, 255}));
  connect(pumChi.port_b, senWatRetTem.port_a) annotation(
      Line(points = {{-84, 78}, {-84, 112}}, color = {0, 170, 0}));
  connect(senWatRetTem.port_b, chiWatRet.ports[1]) annotation(
      Line(points = {{-84, 132}, {-84, 170}}, color = {0, 170, 0}));
  connect(chiWatSup.ports[1], senWatSupTem.port_a) annotation(
      Line(points = {{-32, 170}, {-32, 154}}, color = {0, 170, 0}));
  connect(senWatSupTem.port_b, valChi.port_a) annotation(
      Line(points = {{-32, 134}, {-32, 122}}, color = {0, 170, 0}));
    connect(uWinOpe, winCmdFil.u) annotation (Line(points={{300,110},{248,110},
            {248,-97},{235.8,-97}},
                               color={0,0,127}));
    connect(winCmdFil.y, winOpe.y) annotation (Line(points={{215.1,-97},{154,-97},
            {154,-96},{9,-96}}, color={0,0,127}));
    connect(fanSup.port_b, senSupTem.port_a)
      annotation (Line(points={{4,14},{38,14}}, color={0,127,255}));
    connect(uWinOpe, winOpeBool.u) annotation (Line(points={{300,110},{239.9,110},
            {239.9,111},{179.8,111}},           color={0,0,127}));
    connect(uSysOn, sysOnBool.u) annotation (Line(points={{300,150},{204,150},{204,
            149},{181.8,149}},     color={0,0,127}));
    connect(rooPre.y, phi.p) annotation (Line(points={{-291,260},{-300,260.4},{-312.7,
            260.4}}, color={0,0,127}));
    connect(rooXw.y, phi.X_w) annotation (Line(points={{-291,280},{-300,280},{-300,
            270},{-312.7,270}}, color={0,0,127}));
    connect(rooTem.y, phi.T) annotation (Line(points={{-291,300},{-312.7,300},{-312.7,
            279.6}}, color={0,0,127}));
    connect(phi.phi, RhRoo)
      annotation (Line(points={{-341.3,270},{-370,270}}, color={0,0,127}));
    connect(PASHP, PASHP)
      annotation (Line(points={{-370,242},{-370,242}}, color={0,0,127}));
    connect(PFanRet, PFanRet)
      annotation (Line(points={{-370,192},{-370,192}}, color={0,0,127}));
    connect(sysOnBool.y, piController.sysOn) annotation (Line(points={{161.1,149},
            {102.8,149},{102.8,166.8}}, color={255,0,255}));
    connect(winOpeBool.y, piController.winOpe) annotation (Line(points={{159.1,111},
            {85.52,111},{85.52,166.8}}, color={255,0,255}));
    connect(TRooSet, piController.TRooSet) annotation (Line(points={{300,224},{236,
            224},{236,210},{117.2,210}}, color={0,0,127}));
    connect(CO2Set, piController.CO2Set) annotation (Line(points={{300,192},{224,192},
            {224,182},{117.2,182},{117.2,181.2}}, color={0,0,127}));
    connect(senSupTem.T, piController.TSup) annotation (Line(points={{48,25},{92,25},
            {92,26},{152,26},{152,238.8},{117.2,238.8}}, color={0,0,127}));
    connect(senRooTem.T, piController.TRoo) annotation (Line(points={{109,-50},{108,
            -50},{108,-26},{142,-26},{142,224.4},{117.2,224.4}}, color={0,0,127}));
    connect(senRetCO2.ppm, piController.CO2Meas) annotation (Line(points={{-42,-49},
            {-42,-14},{132,-14},{132,196},{117.2,196},{117.2,195.6}}, color={0,0,127}));
    connect(piController.yPumChi, pumChi.y) annotation (Line(points={{34.4,239.52},
            {-96,239.52},{-96,68}}, color={0,0,127}));
    connect(piController.yValChi, valChi.y) annotation (Line(points={{34.4,226.56},
            {-20,226.56},{-20,112}}, color={0,0,127}));
    connect(piController.yFanSup, fanSup.y) annotation (Line(points={{34.4,206.4},
            {-6,206.4},{-6,26}}, color={0,0,127}));
    connect(piController.yFanRet, fanRet.y) annotation (Line(points={{34.4,194.16},
            {-58,194.16},{-58,194},{-152,194},{-152,-48}}, color={0,0,127}));
    connect(piController.yDamOut, damOut.y) annotation (Line(points={{34.4,180.48},
            {32,180.48},{32,180},{-186,180},{-186,26}}, color={0,0,127}));
    connect(senWatSupTem.T, filteredPowerMeter.TWatSup) annotation (Line(points
          ={{-43,144},{-112,144},{-112,248},{-168.6,248}}, color={0,0,127}));
    connect(senWatRetTem.T, filteredPowerMeter.TWatRet) annotation (Line(points
          ={{-95,122},{-122,122},{-122,241.2},{-168.6,241.2}}, color={0,0,127}));
    connect(senMasFloValv.m_flow, filteredPowerMeter.mChiWat) annotation (Line(
          points={{-21,70},{-20,70},{-20,86},{-132,86},{-132,234.4},{-168.6,
            234.4}}, color={0,0,127}));
    connect(pumChi.P, filteredPowerMeter.PPump) annotation (Line(points={{-93,
            79},{-93,112},{-142,112},{-142,227.6},{-168.6,227.6}}, color={0,0,
            127}));
    connect(fanSup.P, filteredPowerMeter.PSupFanAll) annotation (Line(points={{
            5,23},{5,56},{-158,56},{-158,220.8},{-168.6,220.8}}, color={0,0,127}));
    connect(fanRet.P, filteredPowerMeter.PRetFanAll) annotation (Line(points={{
            -163,-51},{-168.6,-51},{-168.6,214}}, color={0,0,127}));
    connect(sysOnBool.y, filteredPowerMeter.sysOn) annotation (Line(points={{
            161.1,149},{-8,149},{-8,150},{-176,150},{-176,210.6},{-175.4,210.6}},
          color={255,0,255}));
    connect(filteredPowerMeter.PASHP, PASHP) annotation (Line(points={{-207.7,
            246.3},{-264,246.3},{-264,242},{-370,242}}, color={0,0,127}));
    connect(filteredPowerMeter.PPumChi, PPumChi) annotation (Line(points={{
            -207.7,236.1},{-348,236.1},{-348,224},{-370,224}}, color={0,0,127}));
    connect(filteredPowerMeter.PSupFan, PFanSup) annotation (Line(points={{
            -207.7,225.9},{-340,225.9},{-340,206},{-370,206}}, color={0,0,127}));
    connect(filteredPowerMeter.PRetFan, PFanRet) annotation (Line(points={{
            -207.7,215.7},{-336,215.7},{-336,192},{-370,192}}, color={0,0,127}));
    annotation(
      Icon(coordinateSystem(extent = {{-100, 100}, {100, -100}}), graphics = {Rectangle(origin = {2, -1}, lineColor = {0, 0, 255}, fillColor = {173, 216, 230}, fillPattern = FillPattern.Solid, extent = {{-102, 101}, {102, -101}}), Text(origin = {0, 4}, extent = {{-98, 94}, {98, -94}}, textString = "HCD", fontSize = 50)}),
      Diagram(coordinateSystem(extent = {{-380, 320}, {300, -280}})),
      experiment(
        StopTime=1440000,
        Interval=1,
        __Dymola_Algorithm="Ida"));
  end HCDLabPMVPITrain;

  annotation(
    uses(Buildings(version="11.1.0"),   Modelica(version="4.1.0")));
end MMV;
