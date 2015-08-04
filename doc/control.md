This page aims at providing an overview of the integration of the rock-auv
modular control scheme in Syskit. Hopefully, this would be enough to give you
ways to get into the models and the code.

Creating generation rules
-------------------------
The control-cascade generator {RockAUV::Compositions::Control::Generator} is basically a
rule-based engine. It sorts the producers by their output domain (the
        world/position producers being "farther" from the thrusters than the
        body/effort ones) and applies the rules in order to transform the
domains little-by-little until it reaches a body/effort command that
it can feed to the {OroGen::AuvControl::AccelerationController}
controller task.

In the following, the valid reference frames are :world, :aligned and
:body while the valid controlled quantities are :position, :velocity
and :effort.

A rule takes four arguments:
- the rule name
- the input domain as [reference frame, quantity being controlled]
- the output domain as [reference frame, quantity being controlled]
- a set of axis mappings. This specifies that e.g. an input on the X
axis will generate an output on both X and Y.
- the component that should be used to perform the mapping. The
components must behave as OroGen::AuvControl::Base (honestly, just
        subclass it)

The producers should be given as 'name' => InstanceRequirement

Organization in the bundle
--------------------------
A set of control rules basically defines the overall control strategy:
how many controllers you'll have, what they will convert and how they
are going to be chained. In principle, one could mix these strategies
in a single system but ... that's not very recommended.

The bundle therefore segregates each such "control strategy" into (1) its own
namespace in Compositions:: and (2) its own profile.

See for instance {RockAUV::Compositions::StablePitchRoll} and
{RockAUV::Profiles::StablePitchRoll}


