def calculate_owed(tabId)

tab = Tab.first(:id => tabId)

tabTotal = 0
tab.bills.each do |bill|
  tabTotal = Float(tabTotal) + Float(bill.amount)
end
puts "tabTotal = " + tabTotal.to_s
userCount = tab.users.count


userBillPaidAmount = []
userContribution = []
tab.users.each_with_index do |user,n|
  userBillPaidAmount[n] = 0
  userContribution[n] = 0
  user.bills.each do |bill|
    userBillPaidAmount[n] = userBillPaidAmount[n] + bill.amount
  end
  userContributionCalc = tabTotal/userCount - userBillPaidAmount[n]
  userContribution[n] = [user.id, userContributionCalc]
  puts userContributionCalc
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
      #puts 'Credit is credit ' + c.to_s + 'and is equal to ' + credit[1].to_s + 'Debt is debt' + d.to_s + ', and debt[1] is' + debt[1].to_s
      debt[1] = debt[1] + credit[1]
      #puts "User: " + credit[0].to_s
      #puts "Owes " + credit[1].to_s
      #puts "To User: " + debt[0].to_s
      debts[c] = [credit[0], credit[1], debt[0]]
      credit[1] = 0
      #puts debt[1]
    end
  end
end

debtsFinal = []
debts.each_with_index do |debt,n|
  userowed = User.first(:id => debt[0])
  userpaid = User.first(:id => debt[2])
  debtsFinal[n] = [userowed, debt[1], userpaid]
end

debtsFinal
end