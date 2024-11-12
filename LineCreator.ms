global g_selectedObject = undefined
global g_drawingMode = false
global g_vertexDistance = 10.0
global g_emptyMeshObject = undefined
global g_isPolygonCreating = false
global g_surfaceOffset = 5.0
global g_normalDirection = [0,1,0]
global clickCount = 0
global g_selectedMaterial = undefined

global g_uvOffsetX = 0.0 -- Параметр для смещения по X
global g_uvOffsetY = 0.036 -- Параметр для смещения по Y
global g_second_uvOffsetY = 0.011

fn createEmptyMeshObject =
( 	
	g_emptyMeshObject = mesh()  
	g_emptyMeshObject.name = "MeshVertexObject" 
	setNumVerts g_emptyMeshObject 0

	--meshop.applyUVWMap g_emptyMeshObject #planar
	-- Apply selected material if available
	if g_selectedMaterial != undefined then
	(
		g_emptyMeshObject.material = g_selectedMaterial
	)
)

fn createPolygonBetweenVertices =
( 
	if g_emptyMeshObject != undefined then 
	( 
		if g_isPolygonCreating then 
		( 
			local vertexCount = getNumVerts g_emptyMeshObject
			local faceCount = getNumFaces g_emptyMeshObject

			-- Проверка, что есть как минимум 4 вершины 
			if vertexCount >= 4 then 
			( 
				-- Увеличиваем количество граней на 2 
				setNumFaces g_emptyMeshObject (faceCount + 2) true 

				local firstVertexIndex = vertexCount - 3
				local secondVertexIndex = vertexCount - 2
				local thirdVertexIndex = vertexCount - 1
				local fourthVertexIndex = vertexCount

				-- Создаем два треугольника
				setFace g_emptyMeshObject (faceCount + 1) thirdVertexIndex secondVertexIndex fourthVertexIndex
				setFace g_emptyMeshObject (faceCount + 2) thirdVertexIndex firstVertexIndex secondVertexIndex
			
				-- Установка видимости ребер
				setEdgeVis g_emptyMeshObject (faceCount + 1) 3 true
				setEdgeVis g_emptyMeshObject (faceCount + 2) 2 true
				setEdgeVis g_emptyMeshObject (faceCount + 1) 2 true
				setEdgeVis g_emptyMeshObject (faceCount + 2) 1 true
				for faceIndex = faceCount to unwrapMod.getNumFaces() do
				(
					unwrapMod.selectFaces #{faceIndex} -- выбираем полигон
					unwrapMod.detachFaces()            -- разрезаем полигон
				)
				
				meshop.defaultMapFaces g_emptyMeshObject 1
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 1)[0 + faceCount,g_uvOffsetY,0]
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 2) [0 + faceCount,g_second_uvOffsetY,0]
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 3) [1 + faceCount,g_uvOffsetY,0]
				meshop.setMapVert g_emptyMeshObject 1 (faceCount + 4) [1 + faceCount,g_second_uvOffsetY,0]
				
				-- Обновляем объект, чтобы изменения стали видимыми
				unwrapMod.commit()
				update g_emptyMeshObject  
				
			) 
			else 
			( unwrapMod = Unwrap_UVW()
addModifier g_emptyMeshObject unwrapMod
				print "Недостаточно вертексов для создания полигона (нужно минимум 4)." 
			) 
		) 
		else 
		( 
			g_isPolygonCreating = true 
			print "Нажмите еще раз для создания полигона." 
		) 
	) 
	else 
	( 
		print "Сначала создайте пустой объект." 
	)
)

fn getNormalAt hitPos node =
( 
	if (node != undefined and not isDeleted node) then 
	( 
		local nodePos = node.position
		local nodeMaxZ = node.max.z

		local rayStartPos = getViewportPosition()
		local rayDirection = normalize (hitPos - rayStartPos)

		local myRay = ray rayStartPos rayDirection
		local intersection = intersectRay node myRay

		if intersection != undefined then 
		( 
			local hitPosition = intersection.pos
			local intersectionNormal = intersection.dir
			return intersectionNormal
		) 
		else 
		( 
			return [0, 0, 1]
		) 
	) 
	else 
	( 
		return [0, 0, 1]
	)
)

fn getViewportPosition =
( 
	local viewTM = getViewTM()  
	local coordSysTM = Inverse(viewTM)
	local viewportPos = coordSysTM.row4 
	return viewportPos
)

fn createVerticesAtHitPosition hitPos normalDirectionRotate =
( 
	if g_emptyMeshObject != undefined then 
	( 
		local vertexCount = getNumVerts g_emptyMeshObject
		local newVertexCount = vertexCount + 2 
		setNumVerts g_emptyMeshObject newVertexCount true

		local normal = getNormalAt hitPos g_selectedObject
		local firstVertexIndex = vertexCount + 1 
		local secondVertexIndex = vertexCount + 2 

		local normalDirectionRotateNormalized = normalize(normalDirectionRotate)
		local normalNormalized = normalize(normal)

		g_normalDirection = normalDirectionRotate
		local perpendicularNormal = normalize(cross normal g_normalDirection)

		local perpendicularRayPosition = hitPos + (normalNormalized * g_surfaceOffset) + (perpendicularNormal * g_vertexDistance / 2.0)
		setVert g_emptyMeshObject firstVertexIndex perpendicularRayPosition

		local perpendicularNormalInverse = normalize(cross normal -g_normalDirection) 
		local perpendicularRayPositionInverse = hitPos + (normal * g_surfaceOffset) + (perpendicularNormalInverse * g_vertexDistance / 2.0)
		setVert g_emptyMeshObject secondVertexIndex perpendicularRayPositionInverse
		
	) 
	else 
	( 
		print "Сначала создайте пустой объект." 
	) 
	 
	createPolygonBetweenVertices() 
)

global hitPosTest = undefined
global hitPosSecondTest = undefined

fn mouseTrackCallback msg ir obj faceNum shift ctrl alt =
( 
	if g_drawingMode then 
	( 
		if msg == #mousePoint then 
		( 
			if obj != undefined then 
			( 
				if clickCount == 0 then 
				( 
					hitPosTest = ir.pos 
					clickCount += 1 
				) 
				else if clickCount == 1 then 
				( 
					hitPosSecondTest = ir.pos 
					clickCount += 1 
					local normalVector = hitPosSecondTest - hitPosTest 
					local normal = normalize normalVector 
					createVerticesAtHitPosition hitPosTest normal 
					clickCount = 0 
					hitPosTest = undefined 
					hitPosSecondTest = undefined 
				) 
			) 
			else 
			( 
				print "Кликнули, но объект не определен." 
			) 
		) 
	) 
	return #continue
)

fn pickObjectAndSet =
( 
	g_selectedObject = pickObject()  
	if g_selectedObject != undefined then 
	( 
		print ("Выбран объект: " + g_selectedObject.name) 
	)
)

fn enableDrawingMode =
( 
	g_drawingMode = true 
	print "Режим рисования включен. Кликните по объекту для создания вертексов." 
	mouseTrack on:g_selectedObject prompt:"Кликните по поверхности объекта." trackCallback:mouseTrackCallback
)

fn disableDrawingMode =
( 
	g_drawingMode = false 
	print "Режим рисования выключен." 
	mouseTrack off
)

rollout drawingRollout "Режим рисования"
( 
	button btnCreateEmpty "Создать пустой объект" width:150 height:30 
	button btnPick "Выбрать объект" width:150 height:30 
	button btnEnable "Включить режим рисования" width:150 height:30 
	button btnDisable "Выключить режим рисования" width:150 height:30 
	spinner spVertexDistance "Расстояние между вертексами:" range: [0,100,10] type:#float fieldWidth:80 
	materialbutton matSlot "Выбрать материал" width:150 height:30  -- Material button for material selection
	
	-- Label to display the selected material name
	label lblMaterialName "Выбранный материал: None" width:200 height:30 
	
	-- Label to display the name of the empty mesh object
	label lblEmptyObjectName "Пустой объект: None" width:200 height:30
	
	-- Label to display the name of the selected object
	label lblSelectedObjectName "Выбранный объект: None" width:200 height:30

	-- Event handler for material selection
	on matSlot picked mat do
	(
		g_selectedMaterial = mat  -- Store the picked material in the global variable
		print ("Материал выбран: " + g_selectedMaterial.name)
		lblMaterialName.text = "Выбранный материал: " + g_selectedMaterial.name  -- Display material name
		if g_emptyMeshObject != undefined then
		(
			g_emptyMeshObject.material = g_selectedMaterial  -- Apply the selected material to the mesh if it exists
			update g_emptyMeshObject
		)
	)

	-- Event handler for picking an object
	on btnPick pressed do
	( 
		pickObjectAndSet()  -- Function to pick an object and set it to g_selectedObject
		if g_selectedObject != undefined then
		(
			lblSelectedObjectName.text = "Выбранный объект: " + g_selectedObject.name  -- Display selected object name
		)
	) 
	
	on btnCreateEmpty pressed do 
	( 
		createEmptyMeshObject()  
	) 

	on btnEnable pressed do 
	( 
		enableDrawingMode()  
	) 

	on btnDisable pressed do 
	( 
		disableDrawingMode()  
	) 

	on spVertexDistance changed newValue do 
	( 
		g_vertexDistance = newValue 
	)
)

-- Function to pick and set the selected object
fn pickObjectAndSet =
( 
	g_selectedObject = pickObject()  
	if g_selectedObject != undefined then 
	( 
		print ("Выбран объект: " + g_selectedObject.name) 
	)
)

createDialog drawingRollout width:250 height:250


