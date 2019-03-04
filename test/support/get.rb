def get(model, n = 1)
  result = []
  n.times do
    result.push model.create
  end
  result.count > 1 ? result : result[0]
end
