# High level architecture

## Item struct
### Members
1. ID/name
  - Unique identifier for item
2. Quantity
  - Supplier updated variable representing quantity available
  - NOTE:
3. Prices[ (q_1, p_1), (q_2, p_2), ... ]
  - Suppliers enter tuples of quantity and price, which list price per item for
    each quantity threshold
  - NOTE: Price is dependent on quantity ordered (price breaks) and lead time,
    which makes it difficult to determine the optimal data structure to use. We
    have considered static break points, as well as a polynomial function to
    list price for number of products ordered/lead time required.
### Methods
1. Update quantity
2. Replace prices

## Product Registry
### Members
1. Products[]
  - Product
    - Parts[]
      - Part
        - Manufacturer_ID
        - Part_ID
        - Quantity
  - Designer_ID/Address
### Methods
1. Add product
  - Parts array
2. Remove product
### NOTE
Designer may include a "margin part" for profit

## Customer
### Members
1. Funds
2. Bids
  - Product_ID
  - Price
  - Quantity
  - NOTE: bids could include an "AND/OR" condition, to be fulfilled under
    conditionals
### Methods
1. Deposit_funds
2. Withdraw_all
  - withdraw all funds
3. Place_bid - returns Bid_ID
4. Remove_bid

## Alternative Customer
### Members
1. Bids
  - Bid_ID
  - Customer_ID
  - Product_ID
  - Price
  - Quantity

## Execution
### Parameters
1. All relevant bids
  - BidID

### Logic
Pass #1: For each bid
  1. add all products and quantities
  2. keep track of lowest price for each product
  3. also tally list of products for each customer
Pass #2 For each customer
  1. Note total expenditure
  2. Ensure all funds are available
  3. Transfer total funds, revert if shortage
  OR Pass #3 and #4
    3. Debit customers
    4. Transfer funds
5. Remove bids

### NOTE
Additional parameters required to allow part substitution from different
sources

## Dev order
1. Item listing
2. Product Registry
  - Combining items into products 
3. Customer interface
  - Deposit & withdrawals
4. Execute/trigger verification
5. Trigger detection

## Tabled features
1. Pricing formula support
2. Lead time support
3. Logical bidding
4. Time-based bidding
5. Reward for triggering
6. Multiple vendors for the same part
7. Shipping fulfillment
8. Address hashing
