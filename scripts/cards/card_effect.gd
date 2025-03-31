extends Resource
class_name CardEffect

# 效果类型枚举
enum EffectType {
    DAMAGE,        # 伤害
    BLOCK,         # 格挡
    HEAL,          # 治疗
    BUFF,          # 增益效果
    DEBUFF,        # 减益效果
    DRAW,          # 抽牌
    DISCARD,       # 弃牌
    ENERGY,        # 能量
    SPECIAL        # 特殊效果
}

# 效果目标枚举
enum EffectTarget {
    SELF,          # 自身
    ENEMY,         # 敌人
    ALL_ENEMIES,   # 所有敌人
    RANDOM_ENEMY,  # 随机敌人
    ALL            # 所有单位
}

# 基本属性
@export var effect_type: EffectType = EffectType.DAMAGE
@export var target_type: EffectTarget = EffectTarget.ENEMY
@export var value: int = 0
@export var description: String = ""

# 额外参数
@export var extra_params: Dictionary = {}

# 构造函数
func _init(p_type: EffectType = EffectType.DAMAGE, p_target: EffectTarget = EffectTarget.ENEMY, p_value: int = 0):
    effect_type = p_type
    target_type = p_target
    value = p_value
    _update_description()

# 更新描述
func _update_description():
    var effect_name = get_effect_name()
    var target_name = get_target_name()
    var value_string = str(value)
    
    match effect_type:
        EffectType.DAMAGE:
            description = "造成 " + value_string + " 点伤害给" + target_name
        EffectType.BLOCK:
            description = "获得 " + value_string + " 点格挡"
        EffectType.HEAL:
            description = "治疗 " + value_string + " 点生命值给" + target_name
        EffectType.BUFF:
            description = "给予" + target_name + " " + value_string + " 层增益效果"
        EffectType.DEBUFF:
            description = "给予" + target_name + " " + value_string + " 层减益效果"
        EffectType.DRAW:
            description = "抽 " + value_string + " 张牌"
        EffectType.DISCARD:
            description = "弃置 " + value_string + " 张牌"
        EffectType.ENERGY:
            if value > 0:
                description = "获得 " + value_string + " 点能量"
            else:
                description = "失去 " + str(abs(value)) + " 点能量"
        EffectType.SPECIAL:
            description = "特殊效果: " + extra_params.get("description", "")

# 获取效果名称
func get_effect_name() -> String:
    match effect_type:
        EffectType.DAMAGE:
            return "伤害"
        EffectType.BLOCK:
            return "格挡"
        EffectType.HEAL:
            return "治疗"
        EffectType.BUFF:
            return "增益"
        EffectType.DEBUFF:
            return "减益"
        EffectType.DRAW:
            return "抽牌"
        EffectType.DISCARD:
            return "弃牌"
        EffectType.ENERGY:
            return "能量"
        EffectType.SPECIAL:
            return "特殊"
    return "未知"

# 获取目标名称
func get_target_name() -> String:
    match target_type:
        EffectTarget.SELF:
            return "自身"
        EffectTarget.ENEMY:
            return "敌人"
        EffectTarget.ALL_ENEMIES:
            return "所有敌人"
        EffectTarget.RANDOM_ENEMY:
            return "随机敌人"
        EffectTarget.ALL:
            return "所有单位"
    return "未知"

# 应用效果
func apply_effect(source, targets) -> Dictionary:
    # 基本实现，子类可以重写此方法以实现特定效果
    var result = {
        "type": effect_type,
        "value": value,
        "targets": [],
        "success": true,
        "message": ""
    }
    
    # 根据目标类型选择要应用效果的目标
    var actual_targets = []
    
    match target_type:
        EffectTarget.SELF:
            actual_targets = [source]
        EffectTarget.ENEMY:
            if targets.size() > 0:
                actual_targets = [targets[0]]
        EffectTarget.ALL_ENEMIES:
            actual_targets = targets
        EffectTarget.RANDOM_ENEMY:
            if targets.size() > 0:
                actual_targets = [targets[randi() % targets.size()]]
        EffectTarget.ALL:
            actual_targets = [source]
            actual_targets.append_array(targets)
    
    # 对每个目标应用效果
    for target in actual_targets:
        var target_result = _apply_to_target(source, target)
        result.targets.append({
            "target": target,
            "value": target_result.value,
            "success": target_result.success,
            "message": target_result.message
        })
    
    return result

# 对单个目标应用效果
func _apply_to_target(source, target) -> Dictionary:
    var result = {
        "value": value,
        "success": true,
        "message": ""
    }
    
    # 根据效果类型应用不同的效果
    match effect_type:
        EffectType.DAMAGE:
            if "take_damage" in target:
                result.value = target.take_damage(value, source)
                result.message = "%s 受到了 %d 点伤害" % [target.name, result.value]
            else:
                result.success = false
                result.message = "目标无法受到伤害"
        
        EffectType.BLOCK:
            if "add_block" in target:
                result.value = target.add_block(value)
                result.message = "%s 获得了 %d 点格挡" % [target.name, result.value]
            else:
                result.success = false
                result.message = "目标无法获得格挡"
        
        EffectType.HEAL:
            if "heal" in target:
                result.value = target.heal(value)
                result.message = "%s 恢复了 %d 点生命" % [target.name, result.value]
            else:
                result.success = false
                result.message = "目标无法被治疗"
        
        EffectType.BUFF, EffectType.DEBUFF:
            var buff_id = extra_params.get("buff_id", "")
            if buff_id and "add_buff" in target:
                result.value = target.add_buff(buff_id, value, source)
                result.message = "%s 获得了 %d 层 %s" % [target.name, result.value, buff_id]
            else:
                result.success = false
                result.message = "无法应用状态效果"
        
        EffectType.DRAW:
            if source.has_method("draw_cards"):
                result.value = source.draw_cards(value).size()
                result.message = "抽了 %d 张牌" % result.value
            else:
                result.success = false
                result.message = "无法抽牌"
        
        EffectType.DISCARD:
            if source.has_method("discard_random"):
                result.value = source.discard_random(value)
                result.message = "弃置了 %d 张牌" % result.value
            else:
                result.success = false
                result.message = "无法弃牌"
        
        EffectType.ENERGY:
            if "change_energy" in source:
                result.value = source.change_energy(value)
                if value > 0:
                    result.message = "获得了 %d 点能量" % result.value
                else:
                    result.message = "失去了 %d 点能量" % -result.value
            else:
                result.success = false
                result.message = "无法修改能量"
        
        EffectType.SPECIAL:
            var handler = extra_params.get("handler", null)
            if handler and handler.has_method("handle_special_effect"):
                var special_result = handler.handle_special_effect(self, source, target)
                result.value = special_result.value
                result.success = special_result.success
                result.message = special_result.message
            else:
                result.success = false
                result.message = "无法处理特殊效果"
    
    return result

# 复制效果
func duplicate() -> CardEffect:
    var copy = get_script().new(effect_type, target_type, value)
    
    # 复制额外参数
    for key in extra_params:
        var param = extra_params[key]
        if param is Object and param.has_method("duplicate"):
            copy.extra_params[key] = param.duplicate()
        else:
            copy.extra_params[key] = param
    
    copy._update_description()
    return copy 