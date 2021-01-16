#using Pkg
#Pkg.activate(@__DIR__);

#pkg"instantiate"
#pkg"precompile"

# using RigidBodyDynamics, MeshCat, MeshCatMechanisms
# using LinearAlgebra, Printf

# load mechanism
mechanism=parse_urdf("Cheetah.urdf";scalar_type=Float64,floating=true)
remove_fixed_tree_joints!(mechanism)

# create a half space representing ground
hs_p = Point3D(root_frame(mechanism),0.0,0.0,0.0)
hs_v = FreeVector3D(root_frame(mechanism),0.0,0.0,1.0)
hs = RigidBodyDynamics.Contact.HalfSpace3D(hs_p,hs_v)
ce = RigidBodyDynamics.Contact.ContactEnvironment{Float64}()
# add half space to mechanism
push!(ce.halfspaces,hs)
mechanism.environment = ce

# create a soft contact model conmod3
import RigidBodyDynamics.Contact.ViscoelasticCoulombModel
import RigidBodyDynamics.Contact.HuntCrossleyModel
import RigidBodyDynamics.Contact.SoftContactModel
conmod1 = HuntCrossleyModel(50e3,1.5*0.2*50e3,1.5)
conmod2 = ViscoelasticCoulombModel(0.5,10e5,10e3)
conmod3 = SoftContactModel(conmod1,conmod2)

# create contact points on bodies in the Mechanism
cp1 = RigidBodyDynamics.Contact.ContactPoint(Point3D(default_frame(bodies(mechanism)[7]),0.0,0.0,-1.0),conmod3)
add_contact_point!(bodies(mechanism)[7],cp1)
cp1 = RigidBodyDynamics.Contact.ContactPoint(Point3D(default_frame(bodies(mechanism)[8]),0.0,0.0,-1.0),conmod3)
add_contact_point!(bodies(mechanism)[8],cp1)
cp1 = RigidBodyDynamics.Contact.ContactPoint(Point3D(default_frame(bodies(mechanism)[9]),0.0,0.0,-1.0),conmod3)
add_contact_point!(bodies(mechanism)[9],cp1)
cp1 = RigidBodyDynamics.Contact.ContactPoint(Point3D(default_frame(bodies(mechanism)[10]),0.0,0.0,-1.0),conmod3)
add_contact_point!(bodies(mechanism)[10],cp1)

# set the robot state
state=MechanismState(mechanism)
zero_velocity!(state)
set_configuration!(state,[1.0;0;0;0;0;0;2.0;.5;.5;-.5;-.5;-1;-1;1;1])

# PD control on shoulders and joints
function mytorque!(torques::AbstractVector, t, state::MechanismState)
    desvec = [1.0;0;0;0;0;0;0;.1;.1;-.1;-.1;-1;-1;1.0;1.0]
    torques .= 0
    for i=1:8
    torques[6+i]=-5*state.v[6+i] - 100*(state.q[7+i] - desvec[7+i])
    end
end

# define simulation time
final_time = 5.00

# simulate
ts, qs, vs = simulate(state, final_time,mytorque!);

# display
mvis = MechanismVisualizer(mechanism, URDFVisuals("Cheetah.urdf"),vis)
setanimation!(mvis,ts,qs)
#open(mvis2);
