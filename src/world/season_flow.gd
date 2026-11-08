class_name SeasonFlow
extends RefCounted
## Moving between seasons. Season 2 (Kor Vadisi) opens after Season 1's
## ending (flag "sezon1_bitti"): from the season summary or the title.


static func start_season2() -> void:
	var d := GameState.data
	d.start_season2(Content.items)
	SaveGame.write(d)
	SceneFlow.go_to("s2_scene1")
