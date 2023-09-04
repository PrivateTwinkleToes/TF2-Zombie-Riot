#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = {
	"weapons/physcannon/energy_sing_explosion2.wav",
};
static const char g_ChargeSounds[][] = {
	"weapons/physcannon/physcannon_charge.wav",
};


void AlliedSensalAbility_OnMapStart_NPC()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_ChargeSounds));	   i++) { PrecacheSound(g_ChargeSounds[i]);	   }
	PrecacheModel("models/weapons/c_models/c_claymore/c_claymore.mdl");
}

methodmap AlliedSensalAbility < CClotBody
{
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_AUTO, 80, _, 0.9, 100);
	}
	public void PlayChargeSound() 
	{
		EmitSoundToAll(g_ChargeSounds[GetRandomInt(0, sizeof(g_ChargeSounds) - 1)], this.index, SNDCHAN_AUTO, 80, _, 0.9, 100);
	}

	
	public AlliedSensalAbility(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		AlliedSensalAbility npc = view_as<AlliedSensalAbility>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.0", "100", true, true));
		
		i_NpcInternalId[npc.index] = WEAPON_SENSAL_AFTERIMAGE;
		i_NpcWeight[npc.index] = 999;
		SetEntPropEnt(npc.index,   Prop_Send, "m_hOwnerEntity", client);
		
		int ModelIndex;
		char ModelPath[255];
		int entity, i;
			
		SetEntityRenderMode(npc.index, RENDER_TRANSALPHA);
		SetEntityRenderColor(npc.index, 0, 0, 0, 0);


		SetVariantInt(GetEntProp(client, Prop_Send, "m_nBody"));
		AcceptEntityInput(npc.index, "SetBodyGroup");
		
		while(TF2U_GetWearable(client, entity, i, "tf_wearable"))
		{
			ModelIndex = GetEntProp(entity, Prop_Data, "m_nModelIndex");
			if(ModelIndex < 0)
			{
				GetEntPropString(entity, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
			}
			else
			{
				ModelIndexToString(ModelIndex, ModelPath, sizeof(ModelPath));
			}
			if(!ModelPath[0])
				continue;

			for(int Repeat=0; Repeat<7; Repeat++)
			{
				int WearableIndex = i_Wearable[npc.index][Repeat];
				if(!IsValidEntity(WearableIndex))
				{	
					int WearablePostIndex = npc.EquipItem("head", ModelPath);
					i_Wearable[npc.index][Repeat] = EntIndexToEntRef(WearablePostIndex);
					break;
				}
			}
		}
	
		npc.AddActivityViaSequence("taunt_the_fist_bump_fistbump");
		npc.PlayChargeSound();
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_bDissapearOnDeath = true;
		b_NoKnockbackFromSources[npc.index] = true;
		
		npc.m_iBleedType = BLEEDTYPE_METAL;
		npc.m_iStepNoiseType = 0;	
		npc.m_iNpcStepVariation = 0;

		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		b_NpcIsInvulnerable[npc.index] = true;
		
		SDKHook(npc.index, SDKHook_Think, AlliedSensalAbility_ClotThink);

		npc.m_iState = 0;
		npc.m_flSpeed = 0.0;
		npc.m_flAttackHappens_2 = GetGameTime() + 1.5;
		npc.m_flRangedSpecialDelay = GetGameTime() + 3.0;
		
		npc.m_flMeleeArmor = 1.0;
		npc.m_flRangedArmor = 1.0;

		NPC_StopPathing(npc.index);
		b_DoNotUnStuck[npc.index] = true;
		b_NoGravity[npc.index] = true;
		SetEntityCollisionGroup(npc.index, 1); //Dont Touch Anything.
		SetEntProp(npc.index, Prop_Send, "m_usSolidFlags", 12); 
		SetEntProp(npc.index, Prop_Data, "m_nSolidType", 6); 

		return npc;
	}
}

public void AlliedSensalAbility_ClotThink(int iNPC)
{
	AlliedSensalAbility npc = view_as<AlliedSensalAbility>(iNPC);

	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
		return;
	
	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();
	if(npc.m_flAttackHappens_2)
	{
		if(npc.m_flAttackHappens_2 < GetGameTime())
		{
			npc.m_flAttackHappens_2 = 0.0;
			if(IsValidEnemy(npc.index, npc.m_iTarget, true, true))
			{
				AlliedSensalFireLaser(npc.m_iTarget, npc);
			}
			else
			{
				int GetClosestEnemyToAttack;
				GetClosestEnemyToAttack = GetClosestTarget(npc.index,_,_,_,_,_,_,true,_,_,true);
				npc.m_iTarget = GetClosestEnemyToAttack;
				if(npc.m_iTarget > 0)
					AlliedSensalFireLaser(npc.m_iTarget, npc);
			}
		}
		return;
	}
	if(npc.m_flRangedSpecialDelay)
	{
		if(npc.m_flRangedSpecialDelay < GetGameTime())
		{
			RequestFrame(KillNpc, EntIndexToEntRef(npc.index));
		}
	}
}

public void AlliedSensalAbility_NPCDeath(int entity)
{
	AlliedSensalAbility npc = view_as<AlliedSensalAbility>(entity);

	SDKUnhook(npc.index, SDKHook_Think, AlliedSensalAbility_ClotThink);
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	
	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);
	
	if(IsValidEntity(npc.m_iWearable6))
		RemoveEntity(npc.m_iWearable6);

	if(IsValidEntity(npc.m_iWearable7))
		RemoveEntity(npc.m_iWearable7);
}

#define SENSAL_MAX_TARGETS_HIT 10

static int SensalAllied_BEAM_BuildingHit[SENSAL_MAX_TARGETS_HIT];

void Allied_Sensal_InitiateLaserAttack(int owner, int entity, float VectorTarget[3], float VectorStart[3], AlliedSensalAbility npc)
{

	float vecForward[3], vecRight[3], Angles[3];

	MakeVectorFromPoints(VectorStart, VectorTarget, vecForward);
	GetVectorAngles(vecForward, Angles);
	GetAngleVectors(vecForward, vecForward, vecRight, VectorTarget);

	Handle trace = TR_TraceRayFilterEx(VectorStart, Angles, 11, RayType_Infinite, AlliedSensal_TraceWallsOnly);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(VectorTarget, trace);
		
		float lineReduce = 10.0 * 2.0 / 3.0;
		float curDist = GetVectorDistance(VectorStart, VectorTarget, false);
		if (curDist > lineReduce)
		{
			ConformLineDistance(VectorTarget, VectorStart, VectorTarget, curDist - lineReduce);
		}
	}
	delete trace;


	int red = 65;
	int green = 65;
	int blue = 255;
	float diameter = float(40);
	//we set colours of the differnet laser effects to give it more of an effect
	
	float flPos[3];
	float flAng[3];
	GetAttachment(entity, "effect_hand_r", flPos, flAng);

	int colorLayer4[4];
	SetColorRGBA(colorLayer4, red, green, blue, 60);
	int colorLayer3[4];
	SetColorRGBA(colorLayer3, colorLayer4[0] * 7 + 255 / 8, colorLayer4[1] * 7 + 255 / 8, colorLayer4[2] * 7 + 255 / 8, 60);
	int colorLayer2[4];
	SetColorRGBA(colorLayer2, colorLayer4[0] * 6 + 510 / 8, colorLayer4[1] * 6 + 510 / 8, colorLayer4[2] * 6 + 510 / 8, 60);
	int colorLayer1[4];
	SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 765 / 8, colorLayer4[1] * 5 + 765 / 8, colorLayer4[2] * 5 + 765 / 8, 60);

	TE_SetupBeamPoints(flPos, VectorTarget, Shared_BEAM_Laser, 0, 0, 0, 0.11, ClampBeamWidth(diameter * 0.3 * 1.28), ClampBeamWidth(diameter * 0.3 * 1.28), 0, 1.0, colorLayer1, 3);
	TE_SendToAll(0.0);
	TE_SetupBeamPoints(flPos, VectorTarget, Shared_BEAM_Laser, 0, 0, 0, 0.22, ClampBeamWidth(diameter * 0.5 * 1.28), ClampBeamWidth(diameter * 0.5 * 1.28), 0, 1.0, colorLayer2, 3);
	TE_SendToAll(0.0);
	TE_SetupBeamPoints(flPos, VectorTarget, Shared_BEAM_Laser, 0, 0, 0, 0.22, ClampBeamWidth(diameter * 0.8 * 1.28), ClampBeamWidth(diameter * 0.8 * 1.28), 0, 1.0, colorLayer3, 3);
	TE_SendToAll(0.0);
	TE_SetupBeamPoints(flPos, VectorTarget, Shared_BEAM_Laser, 0, 0, 0, 0.33, ClampBeamWidth(diameter * 1.28), ClampBeamWidth(diameter * 1.28), 0, 1.0, colorLayer4, 3);
	TE_SendToAll(0.0);

	float hullMin[3];
	float hullMax[3];
	hullMin[0] = -float(40);
	hullMin[1] = hullMin[0];
	hullMin[2] = hullMin[0];
	hullMax[0] = -hullMin[0];
	hullMax[1] = -hullMin[1];
	hullMax[2] = -hullMin[2];
	npc.PlayDeathSound();
	npc.DispatchParticleEffect(npc.index, "mvm_soldier_shockwave", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, npc.FindAttachment("effect_hand_r"), PATTACH_POINT_FOLLOW, true);
	
	for (int building = 1; building < SENSAL_MAX_TARGETS_HIT; building++)
	{
		SensalAllied_BEAM_BuildingHit[building] = 0;
	}

	trace = TR_TraceHullFilterEx(VectorStart, VectorTarget, hullMin, hullMax, 1073741824, BEAM_TraceUsers, entity);	// 1073741824 is CONTENTS_LADDER?
	delete trace;

	int Weapon = EntRefToEntIndex(i_Changed_WalkCycle[npc.index]);
	float DamageFallOff = 1.0;
	for (int building = 0; building < SENSAL_MAX_TARGETS_HIT; building++)
	{
		if (SensalAllied_BEAM_BuildingHit[building])
		{
			if(IsValidEntity(SensalAllied_BEAM_BuildingHit[building]))
			{
				float damage = fl_heal_cooldown[entity];

				SDKHooks_TakeDamage(SensalAllied_BEAM_BuildingHit[building], owner, entity, damage / DamageFallOff, DMG_CLUB, Weapon, NULL_VECTOR, WorldSpaceCenter(SensalAllied_BEAM_BuildingHit[building]), _ , ZR_DAMAGE_NOAPPLYBUFFS_OR_DEBUFFS);	// 2048 is DMG_NOGIB?
				DamageFallOff *= LASER_AOE_DAMAGE_FALLOFF;				
			}
		}
	}
}

static bool BEAM_TraceUsers(int entity, int contentsMask, int client)
{
	if (IsValidEntity(entity))
	{
		entity = Target_Hit_Wand_Detection(client, entity);
		if(0 < entity)
		{
			for(int i=0; i < (SENSAL_MAX_TARGETS_HIT); i++)
			{
				if(!SensalAllied_BEAM_BuildingHit[i])
				{
					SensalAllied_BEAM_BuildingHit[i] = entity;
					break;
				}
			}
		}
	}
	return false;
}
void AlliedSensalFireLaser(int target, AlliedSensalAbility npc)
{
	int owner = GetEntPropEnt(npc.index, Prop_Data, "m_hOwnerEntity");
	Allied_Sensal_InitiateLaserAttack(owner, npc.index, WorldSpaceCenter(target), WorldSpaceCenter(npc.index), npc);
}

public bool AlliedSensal_TraceWallsOnly(int entity, int contentsMask)
{
	return !entity;
}