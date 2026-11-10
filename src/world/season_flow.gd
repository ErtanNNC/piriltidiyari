class_name SeasonFlow
extends RefCounted
## Moving between seasons. Season 2 (Kor Vadisi) opens after Season 1's
## ending (flag "sezon1_bitti"), Season 3 (Titrek Kıyılar) after Season 2's
## ("sezon2_bitti"): from the season summary or the title.


static func start_season2() -> void:
	var d := GameState.data
	d.start_season2(Content.items)
	SaveGame.write(d)
	SceneFlow.go_to("s2_scene1")


static func start_season3() -> void:
	var d := GameState.data
	d.start_season3(Content.items)
	SaveGame.write(d)
	SceneFlow.go_to("s3_scene1")
