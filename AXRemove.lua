for _, Item in pairs(game:GetService("CoreGui"):GetDescendants()) do
	if Item:IsA("TextLabel") and Item.Text == "📆 Arceus X Origin"  then
		Item.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent:Destroy()
		break
	end
end
