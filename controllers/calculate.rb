def calculate_owed(tabId)

tab = Tab.first(:id => tabId)

tabTotal = 0
tab.bills.each do |bill|
  tabTotal = tabTotal + bill.amount
end

userCount = tab.users.count

userBillPaidAmount = []
userContribution = []
tab.users.each_with_index do |user,n|
  userBillPaidAmount[n] = 0
  userContribution[n] = 0
  user.bills.each do |bill|
    userBillPaidAmount[n] = userBillPaidAmount[n] + bill.amount
  end
  userContribution[n] = [user.id, tabTotal/userCount - userBillPaidAmount[n]]
  puts userContribution[n]
end



userIds = []
tab.users.each_with_index do |user,n|
  userIds[n] = user.id
end

debtsToBePaid = []
tab.users.each_with_index do |user, n|
  if(userContribution[n][1] <= 0)
    debtsToBePaid[n] = userContribution[n]
  end
  puts 'User ' + user.id.to_s + ' Contribution: ' + userContribution[n][1].to_s
end

usersToPayDebts = []
tab.users.each_with_index do |user, n|
  if(userContribution[n][1] > 0)
    usersToPayDebts.push(userContribution[n])
  end
end


debts = []
debtsToBePaid.each_with_index do |debt, d|
  #cycle over each debt to figure out who to pay it
  usersToPayDebts.each_with_index do |credit, c|
  #cycle over each person with credit to assign them debt to pay
    if(credit[1] > 0)
      debt[1] = debt[1] - credit[1]
      debts[d[c[0]]] = credit[0]
      debts[d[c[1]]] = credit[1]
      debts[d[c[1]]] = debt[0]
      puts "User: " + credit[0].to_s
      puts "Owes " + credit[1].to_s
      puts "To User: " + debt[0].to_s
      debts[d] = [credit[0], credit[1], debt[0]]
    end
  end
end

debts
end