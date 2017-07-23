import "relay/Guide/Support/LocationAvailable.ash"
import "relay/Guide/Support/Equipment Requirement.ash"
import "relay/Guide/Support/HTML.ash"
import "relay/Guide/Support/Statics 2.ash"



string HTMLGenerateFutureTextByLocationAvailability(string base_text, location place)
{
    if (!place.locationAvailable() && place != $location[none])
    {
        base_text = HTMLGenerateSpanOfClass(base_text, "r_future_option");
    }
    return base_text;
}

string HTMLGenerateFutureTextByLocationAvailability(location place)
{
	return HTMLGenerateFutureTextByLocationAvailability(place.to_string(), place);
}

//Alternate name, since last time I tried making this function then discovered the "generate future text" options which I cleverly named in such a way that I would never find it
string HTMLGreyOutIfLocationUnavailable(string source, location l)
{
    return HTMLGenerateFutureTextByLocationAvailability(source, l);
}
string HTMLBoldIfTrue(string base_text, boolean conditional)
{
    if (conditional)
        return HTMLGenerateSpanOfClass(base_text, "r_bold");
    return base_text;
}


boolean can_equip_replacement(item it)
{
    if (it.equipped_amount() > 0)
        return true;
    boolean can_equip = it.can_equip();
    if (can_equip)
        return true;
    if (my_class() == $class[pastamancer])
    {
        //Bind Undead Elbow Macaroni -> equalises muscle
        //Bind Penne Dreadful -> equalises moxie
        EquipmentStatRequirement requirement = it.StatRequirementForEquipment();
        
        if (requirement.requirement_stat == $stat[none])
            return true;
        if (my_basestat(requirement.requirement_stat) >= requirement.requirement_amount)
            return true;
        if (requirement.requirement_stat == $stat[mysticality])
            return false;
        
        if (requirement.requirement_stat == $stat[muscle])
        {
            if ($skill[bind undead elbow macaroni].have_skill() && my_basestat($stat[mysticality]) >= requirement.requirement_amount)
                return true;
        }
        else if (requirement.requirement_stat == $stat[moxie])
        {
            if ($skill[Bind Penne Dreadful].have_skill() && my_basestat($stat[mysticality]) >= requirement.requirement_amount)
                return true;
        }
    }
    return can_equip;
}

boolean can_equip_outfit(string outfit_name)
{
    if (!have_outfit_components(outfit_name))
        return false;
    item [int] outfit_pieces = outfit_pieces(outfit_name);
    foreach key, it in outfit_pieces
    {
        if (!it.can_equip_replacement())
            return false;
    }
    return true;
}


//Probably not a good place for it:
boolean asdonMartinFailsFuelableTestsPrivate(item craft, boolean [item] ingredients_blacklisted, item last_recurse_ingredient)
{
    //if ($items[wad of dough,flat dough] contains craft) return false;
    if (craft.craft_type().contains_text("(fancy)"))
        return true;
    boolean all_npc = true;
    foreach it, amount in craft.get_ingredients()
    {
        if (ingredients_blacklisted[it]) return true;
        if (it.item_amount() >= amount) continue;
        if (it == last_recurse_ingredient) //wad of dough, flat dough, jolly roger charrrm
        {
            continue;
        }
        if (it.asdonMartinFailsFuelableTestsPrivate(ingredients_blacklisted, craft))
            return true;
        if (it.npc_price() == 0)
            all_npc = false;
    }
    if (craft.get_ingredients().count() == 0)
        all_npc = false;
    if (all_npc)
        return true;
    return false;
}

boolean asdonMartinFailsFuelableTests(item craft, boolean [item] ingredients_blacklisted)
{
    return asdonMartinFailsFuelableTestsPrivate(craft, ingredients_blacklisted, $item[none]);
}

item [int] asdonMartinGenerateListOfFuelables()
{
    item [int] fuelables;
    boolean [item] blacklist;
    if (!QuestState("questL11Black").finished) //FIXME no
        blacklist[$item[blackberry]] = true; //FIXME test properly?
    blacklist[$item[stunt nuts]] = true;
    blacklist[$item[wet stew]] = true; //FIXME I guess maybe not after
    blacklist[$item[goat cheese]] = true;
    blacklist[$item[hot wing]] = true;
    blacklist[$item[glass of goat's milk]] = true;
    blacklist[$item[soft green echo eyedrop antidote martini]] = true; //if it's not created, FIXME
    blacklist[$item[cashew]] = true;
    blacklist[$item[warm gravy]] = true; //don't steal my boat
    foreach it in $items[Falcon&trade; Maltese Liquor, hardboiled egg]
        blacklist[it] = true; //don't steal my -combat
    blacklist[$item[loaf of soda bread]] = true; //elsewhere
    foreach it in $items[hot buttered roll,ketchup,catsup]
        blacklist[it] = true; //hermit
    foreach it in $items[bottle of gin,bottle of rum,bottle of vodka,bottle of whiskey,bottle of tequila] //too useful for crafting?
        blacklist[it] = true;
    foreach it in $items[bottle of Calcutta Emerald,bottle of Lieutenant Freeman,bottle of Jorge Sinsonte,bottle of Definit,bottle of Domesticated Turkey,boxed champagne,bottle of Ooze-O,bottle of Pete's Sake,tangerine,kiwi,cocktail onion,kumquat,tonic water,raspberry] //nash crosby's still's results isn't feedable
        blacklist[it] = true;
    foreach it in __pvpable_food_and_drinks
    {
        if (blacklist[it]) continue;
        if (it.is_npc_item()) continue;
        if (it.historical_price() >= 20000) continue;
        if (it.item_amount() == 0)
        {
            if (it.creatable_amount() == 0)
                continue;
            if (it.asdonMartinFailsFuelableTests(blacklist))
                continue;
        }
        if (my_path_id() == PATH_LICENSE_TO_ADVENTURE && false)
        {
            if (it.inebriety > 0 && it.image == "martini.gif")
                continue;
        }
        int [item] ingredients = it.get_ingredients();
        if (ingredients.count() > 0)
        {
            boolean reject = false;
            //Various things count as being from a "store":
            foreach it in $items[yellow pixel,handful of barley]
            {
                if (ingredients[it] > 0)
                {
                    reject = true;
                    break;
                }
            }
            if (reject)
                continue;
        }
        float average_adventures = it.averageAdventuresForConsumable();
        if (average_adventures == 0.0)
            continue;
            
        float soda_bread_efficiency = to_float($item[wad of dough].npc_price() + $item[soda water].npc_price()) / 6.0;
        if (soda_bread_efficiency < 1.0) soda_bread_efficiency = 100000.0;
        if (it.autosell_price() > 0 && it.autosell_price().to_float() / average_adventures > soda_bread_efficiency)
        {
            continue;
        }
        fuelables.listAppend(it);
    }
    sort fuelables by -value.averageAdventuresForConsumable() * value.item_amount();
    return fuelables;
}
