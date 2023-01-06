#pragma semicolon 1
#pragma newdecls required

static float fl_tornados_rockets_eated[MAXPLAYERS+1]={0.0, ...};
static int i_tornado_index[MAXENTITIES+1];
static int i_tornado_wep[MAXENTITIES+1];
static float fl_tornado_dmg[MAXENTITIES+1];
static int g_ProjectileModel;


#define SOUND_IMPACT_1 					"physics/flesh/flesh_impact_bullet1.wav"	//We hit flesh, we are also kinetic, yes.
#define SOUND_IMPACT_2 					"physics/flesh/flesh_impact_bullet2.wav"
#define SOUND_IMPACT_3 					"physics/flesh/flesh_impact_bullet3.wav"
#define SOUND_IMPACT_4 					"physics/flesh/flesh_impact_bullet4.wav"
#define SOUND_IMPACT_5 					"physics/flesh/flesh_impact_bullet5.wav"

#define SOUND_IMPACT_CONCRETE_1			"physics/concrete/concrete_impact_bullet1.wav"//we hit the ground? HOW DARE YOU MISS?
#define SOUND_IMPACT_CONCRETE_2 		"physics/concrete/concrete_impact_bullet2.wav"
#define SOUND_IMPACT_CONCRETE_3 		"physics/concrete/concrete_impact_bullet3.wav"
#define SOUND_IMPACT_CONCRETE_4 		"physics/concrete/concrete_impact_bullet4.wav"

public void Weapon_Tornado_Blitz_Precache()
{
	PrecacheSound(SOUND_IMPACT_CONCRETE_1);
	PrecacheSound(SOUND_IMPACT_CONCRETE_2);
	PrecacheSound(SOUND_IMPACT_CONCRETE_3);
	PrecacheSound(SOUND_IMPACT_CONCRETE_4);
	
	PrecacheSound(SOUND_IMPACT_1);
	PrecacheSound(SOUND_IMPACT_2);
	PrecacheSound(SOUND_IMPACT_3);
	PrecacheSound(SOUND_IMPACT_4);
	PrecacheSound(SOUND_IMPACT_5);
	
	static char model[PLATFORM_MAX_PATH];
	model = "models/weapons/w_bullet.mdl";
	g_ProjectileModel = PrecacheModel(model);
}

public void Weapon_tornado_launcher_Spam(int client, int weapon, const char[] classname, bool &result)
{
	if(fl_tornados_rockets_eated[client]>3.0)	//Every 3rd rocket is free. or there abouts.
	{
		Add_Back_One_Rocket(weapon);
		fl_tornados_rockets_eated[client]=-3.0;
	}
	else
	{
		fl_tornados_rockets_eated[client]+=1.25;
	}
	Weapon_Tornado_Launcher_Spam_Fire_Rocket(client, weapon);
}

public void Weapon_tornado_launcher_Spam_Pap1(int client, int weapon, const char[] classname, bool &result)
{
	if(fl_tornados_rockets_eated[client]<0.49)	//2 rockets eated, 1 free.
	{
		Add_Back_One_Rocket(weapon);
		fl_tornados_rockets_eated[client]++;
	}
	else
	{
		fl_tornados_rockets_eated[client]-=0.5;
	}
	Weapon_Tornado_Launcher_Spam_Fire_Rocket(client, weapon);
}

public void Weapon_tornado_launcher_Spam_Pap2(int client, int weapon, const char[] classname, bool &result)
{
	if(fl_tornados_rockets_eated[client]<1.0)	//Half rockets eated, other half free
	{
		Add_Back_One_Rocket(weapon);
		fl_tornados_rockets_eated[client]++;
	}
	else
	{
		fl_tornados_rockets_eated[client]=0.0;
	}
	Weapon_Tornado_Launcher_Spam_Fire_Rocket(client, weapon);
}

public void Weapon_tornado_launcher_Spam_Pap3(int client, int weapon, const char[] classname, bool &result)
{
	if(fl_tornados_rockets_eated[client]<2.0)	//4x clip size, basically, most of it being free.
	{
		Add_Back_One_Rocket(weapon);
		fl_tornados_rockets_eated[client]++;
	}
	else
	{
		fl_tornados_rockets_eated[client]=0.0;
	}
	Weapon_Tornado_Launcher_Spam_Fire_Rocket(client, weapon);
}

void Add_Back_One_Rocket(int entity)
{
	if(IsValidEntity(entity))
	{
		int iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		int ammo = GetEntData(entity, iAmmoTable, 4);
		ammo += 1;

		SetEntData(entity, iAmmoTable, ammo, 4, true);
	}
}
void Weapon_Tornado_Launcher_Spam_Fire_Rocket(int client, int weapon)
{
	if(weapon >= MaxClients)
	{
		
		float speedMult = 1250.0;
		float dmgProjectile = 100.0;
		
		
		//note: redo attributes for better customizability
		Address address = TF2Attrib_GetByDefIndex(weapon, 2);
		if(address != Address_Null)
			dmgProjectile *= TF2Attrib_GetValue(address);
			
		address = TF2Attrib_GetByDefIndex(weapon, 103);
		if(address != Address_Null)
			speedMult *= TF2Attrib_GetValue(address);
		
		address = TF2Attrib_GetByDefIndex(weapon, 104);
		if(address != Address_Null)
			speedMult *= TF2Attrib_GetValue(address);
		
		address = TF2Attrib_GetByDefIndex(weapon, 475);
		if(address != Address_Null)
			speedMult *= TF2Attrib_GetValue(address);
			
		float damage=dmgProjectile;
			
		BlitzRocket(client, speedMult, damage, weapon);
	}
}

void BlitzRocket(int client, float speed, float damage, int weapon)
{
	float fAng[3], fPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);
	
	float CustomAng[3] = {0.0,0.0,0.0};	//This part is incomplete. for now...
	
	if(CustomAng[0] != 0.0 || CustomAng[1] != 0.0)
	{
		fAng[0] = CustomAng[0];
		fAng[1] = CustomAng[1];
		fAng[2] = CustomAng[2];
	}


	float tmp[3];
	float actualBeamOffset[3];
	float BEAM_BeamOffset[3];
	BEAM_BeamOffset[0] = 0.0;
	BEAM_BeamOffset[1] = -8.0;
	BEAM_BeamOffset[2] = -10.0;

	tmp[0] = BEAM_BeamOffset[0];
	tmp[1] = BEAM_BeamOffset[1];
	tmp[2] = 0.0;
	VectorRotate(tmp, fAng, actualBeamOffset);
	actualBeamOffset[2] = BEAM_BeamOffset[2];
	fPos[0] += actualBeamOffset[0];
	fPos[1] += actualBeamOffset[1];
	fPos[2] += actualBeamOffset[2];


	float fVel[3], fBuf[3];
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*speed;
	fVel[1] = fBuf[1]*speed;
	fVel[2] = fBuf[2]*speed;

	int entity = CreateEntityByName("tf_projectile_rocket");
	if(IsValidEntity(entity))
	{
		fl_tornado_dmg[entity]=damage;
		i_tornado_wep[entity]=weapon;
		i_tornado_index[entity]=client;
		b_EntityIsArrow[entity] = true;
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client); //No owner entity! woo hoo
		SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, 0.0, true);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetEntProp(client, Prop_Send, "m_iTeamNum"));
		TeleportEntity(entity, fPos, fAng, NULL_VECTOR);
		DispatchSpawn(entity);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVel);
		
		for(int i; i<4; i++)
		{
			SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_ProjectileModel, _, i);
		}
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 3.0);
		g_DHookRocketExplode.HookEntity(Hook_Pre, entity, Tornado_RocketExplodePre); //In this case I reused code that was reused due to laziness, I am the ultiamte lazy. *yawn*
		SDKHook(entity, SDKHook_ShouldCollide, Never_ShouldCollide);
		SDKHook(entity, SDKHook_StartTouch, Tornado_Blitz_StartTouch);
	}
	return;
}
public MRESReturn Tornado_RocketExplodePre(int entity)
{
	//CPrintToChatAll("explode pre");
	return MRES_Supercede;
}
public void Tornado_Blitz_StartTouch(int entity, int other)
{
	int target = Target_Hit_Wand_Detection(entity, other);
	if (target > 0)	
	{
		//Code to do damage position and ragdolls
		static float angles[3];
		GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
		float vecForward[3];
		GetAngleVectors(angles, vecForward, NULL_VECTOR, NULL_VECTOR);
		static float Entity_Position[3];
		Entity_Position = WorldSpaceCenter(target);
		
		int owner = EntRefToEntIndex(i_tornado_index[entity]);
		int weapon = EntRefToEntIndex(i_tornado_wep[entity]);

		SDKHooks_TakeDamage(target, owner, owner, fl_tornado_dmg[entity], DMG_BULLET, weapon, CalculateDamageForce(vecForward, 10000.0), Entity_Position);	// 2048 is DMG_NOGIB?
		
		//CPrintToChatAll("sdk_dmg");
		
		switch(GetRandomInt(1,5)) 
		{
			case 1:EmitSoundToAll(SOUND_IMPACT_1, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 2:EmitSoundToAll(SOUND_IMPACT_2, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 3:EmitSoundToAll(SOUND_IMPACT_3, entity, SNDCHAN_STATIC, 80, _, 0.9);
			
			case 4:EmitSoundToAll(SOUND_IMPACT_4, entity, SNDCHAN_STATIC, 80, _, 0.9);
			
			case 5:EmitSoundToAll(SOUND_IMPACT_5, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
	   	}
		RemoveEntity(entity);
	}
	else if(target == 0)
	{
		switch(GetRandomInt(1,4)) 
		{
			case 1:EmitSoundToAll(SOUND_IMPACT_CONCRETE_1, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 2:EmitSoundToAll(SOUND_IMPACT_CONCRETE_2, entity, SNDCHAN_STATIC, 80, _, 0.9);
				
			case 3:EmitSoundToAll(SOUND_IMPACT_CONCRETE_3, entity, SNDCHAN_STATIC, 80, _, 0.9);
			
			case 4:EmitSoundToAll(SOUND_IMPACT_CONCRETE_4, entity, SNDCHAN_STATIC, 80, _, 0.9);
		}
		RemoveEntity(entity);
	}
	return;
}